$ErrorActionPreference = 'Stop'

$projectRoot = $PSScriptRoot
$outputDirectory = Join-Path $projectRoot 'Bin\Win64\Debug'
$backendExecutable = Join-Path $outputDirectory 'BrickStack2Backend.exe'
$uiExecutable = Join-Path $outputDirectory 'BrickStack2UI.exe'
$sqliteRuntime = Join-Path $outputDirectory 'sqlite3.dll'
$catalogDatabase = Join-Path $outputDirectory 'DBase\rb.db'
$runId = [Guid]::NewGuid().ToString('N')
$sandboxDirectory = Join-Path $outputDirectory ('.collection-http-test-' + $runId)
$backendProcess = $null
$uiProcess = $null

function Assert-Equal($Actual, $Expected, [string] $Description) {
    if ($Actual -ne $Expected) {
        throw "$Description. Expected '$Expected', got '$Actual'."
    }
}

function Assert-True([bool] $Condition, [string] $Description) {
    if (-not $Condition) {
        throw $Description
    }
}

function Assert-PortAvailable([int] $Port) {
    $listener = Get-NetTCPConnection -LocalPort $Port -State Listen `
        -ErrorAction SilentlyContinue
    if ($listener) {
        throw "Port $Port is already in use; refusing to run against another BrickStack2 service."
    }
}

function Wait-ForHealth([string] $Uri, [System.Diagnostics.Process] $Process) {
    $deadline = [DateTime]::UtcNow.AddSeconds(60)
    while ([DateTime]::UtcNow -lt $deadline) {
        $Process.Refresh()
        if ($Process.HasExited) {
            throw "Service exited before becoming ready: $Uri"
        }
        try {
            Invoke-RestMethod -Uri $Uri -TimeoutSec 2 | Out-Null
            return
        }
        catch {
            Start-Sleep -Milliseconds 250
        }
    }
    throw "Timed out waiting for service: $Uri"
}

function Invoke-JsonApi([string] $Method, [string] $Uri,
    [Microsoft.PowerShell.Commands.WebRequestSession] $Session, $Body = $null) {
    $parameters = @{
        Uri = $Uri
        Method = $Method
        WebSession = $Session
        Headers = @{ 'X-BrickStack-Request' = '1' }
        TimeoutSec = 60
    }
    if ($null -ne $Body) {
        $parameters.ContentType = 'application/json'
        $parameters.Body = $Body | ConvertTo-Json -Compress
    }
    return Invoke-RestMethod @parameters
}

function Get-HttpStatus([string] $Method, [string] $Uri,
        [Microsoft.PowerShell.Commands.WebRequestSession] $Session, $Body = $null,
        [bool] $IncludeRequestHeader = $true) {
        $parameters = @{
        Uri = $Uri
        Method = $Method
        Headers = @{}
        UseBasicParsing = $true
        TimeoutSec = 60
    }
    if ($IncludeRequestHeader) {
        $parameters.WebSession = $Session
        $parameters.Headers['X-BrickStack-Request'] = '1'
    } else {
        $csrfSession = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
        $uiOrigin = [uri]'http://127.0.0.1:8080/'
        foreach ($cookie in $Session.Cookies.GetCookies($uiOrigin)) {
            $csrfSession.Cookies.Add($uiOrigin, $cookie)
        }
        $parameters.WebSession = $csrfSession
    }
    if ($null -ne $Body) {
        $parameters.ContentType = 'application/json'
        $parameters.Body = $Body | ConvertTo-Json -Compress
    }
    try {
        $response = Invoke-WebRequest @parameters
        return [int]$response.StatusCode
    }
    catch {
        if ($null -eq $_.Exception.Response) {
            throw
        }
        return [int]$_.Exception.Response.StatusCode
    }
}

function ConvertTo-Hex([byte[]] $Bytes) {
    return [BitConverter]::ToString($Bytes).Replace('-', '')
}

function New-PasswordHash([string] $Password, [byte[]] $Salt) {
    $deriveBytes = [System.Security.Cryptography.Rfc2898DeriveBytes]::new(
        $Password, $Salt, 600000,
        [System.Security.Cryptography.HashAlgorithmName]::SHA256)
    try {
        return ConvertTo-Hex ($deriveBytes.GetBytes(32))
    }
    finally {
        $deriveBytes.Dispose()
    }
}

function Quote-Sql([string] $Value) {
    return "'" + $Value.Replace("'", "''") + "'"
}

function Seed-TestUsers([string] $DatabaseFile) {
    $userSuffix = $runId.Substring(0, 12)
    $users = @(
        @{ Id = 2; Name = "owner-a-$userSuffix"; DisplayName = 'Collection Owner A'; Password = "Integration-Test-$runId-A" },
        @{ Id = 3; Name = "owner-b-$userSuffix"; DisplayName = 'Collection Owner B'; Password = "Integration-Test-$runId-B" }
    )
    $statements = [System.Collections.Generic.List[string]]::new()
    foreach ($user in $users) {
        $salt = New-Object byte[] 16
        $random = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        try {
            $random.GetBytes($salt)
        }
        finally {
            $random.Dispose()
        }
        $passwordHash = New-PasswordHash $user.Password $salt
        $statements.Add(
            'INSERT INTO BSUsers ' +
            '(ID, UserName, DisplayName, PasswordHash, PasswordSalt, ' +
            'PasswordAlgorithm, Role, IsEnabled, MustChangePassword) VALUES (' +
            $user.Id + ', ' + (Quote-Sql $user.Name) + ', ' +
            (Quote-Sql $user.DisplayName) + ', ' +
            (Quote-Sql $passwordHash) + ', ' + (Quote-Sql (ConvertTo-Hex $salt)) +
            ', ''PBKDF2-HMAC-SHA256-600000'', 1, 1, 0)')
    }

    $sql = 'BEGIN IMMEDIATE;' + [Environment]::NewLine +
        ($statements -join (';' + [Environment]::NewLine)) + ';' +
        [Environment]::NewLine + 'COMMIT;'
    [BrickStack2CollectionTestSqlite]::Execute($DatabaseFile, $sql)
    return $users
}

function New-UserSession($User, [string] $BaseUrl) {
    $session = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
    $login = Invoke-JsonApi 'POST' "$BaseUrl/api/auth/login" $session @{
        username = $User.Name
        password = $User.Password
    }
    Assert-True $login.authenticated `
        "Test account did not authenticate: $($User.Name)"
    return $session
}

try {
    foreach ($path in @($backendExecutable, $uiExecutable, $sqliteRuntime,
            $catalogDatabase)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Required built file is missing: $path"
        }
    }
    Assert-PortAvailable 8080
    Assert-PortAvailable 8081

    $sandboxDBase = Join-Path $sandboxDirectory 'DBase'
    New-Item -ItemType Directory -Path $sandboxDBase -Force | Out-Null
    Copy-Item -LiteralPath $backendExecutable -Destination $sandboxDirectory
    Copy-Item -LiteralPath $sqliteRuntime -Destination $sandboxDirectory
    New-Item -ItemType HardLink `
        -Path (Join-Path $sandboxDBase 'rb.db') `
        -Target $catalogDatabase | Out-Null

    $sqlitePathForCSharp = $sqliteRuntime.Replace('\', '\\')
    $sqliteSource = @"
using System;
using System.Runtime.InteropServices;

public static class BrickStack2CollectionTestSqlite
{
    [DllImport(@"$sqlitePathForCSharp", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
    private static extern int sqlite3_open(string filename, out IntPtr database);

    [DllImport(@"$sqlitePathForCSharp", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
    private static extern int sqlite3_exec(IntPtr database, string sql, IntPtr callback, IntPtr argument, out IntPtr errorMessage);

    [DllImport(@"$sqlitePathForCSharp", CallingConvention = CallingConvention.Cdecl)]
    private static extern int sqlite3_close(IntPtr database);

    [DllImport(@"$sqlitePathForCSharp", CallingConvention = CallingConvention.Cdecl)]
    private static extern void sqlite3_free(IntPtr memory);

    public static void Execute(string filename, string sql)
    {
        IntPtr database;
        int result = sqlite3_open(filename, out database);
        if (result != 0)
            throw new InvalidOperationException("Could not open the isolated test database.");
        try
        {
            IntPtr errorMessage;
            result = sqlite3_exec(database, sql, IntPtr.Zero, IntPtr.Zero, out errorMessage);
            if (result != 0)
            {
                string message = errorMessage == IntPtr.Zero
                    ? "SQLite test setup failed."
                    : Marshal.PtrToStringAnsi(errorMessage);
                if (errorMessage != IntPtr.Zero)
                    sqlite3_free(errorMessage);
                throw new InvalidOperationException(message);
            }
        }
        finally
        {
            sqlite3_close(database);
        }
    }
}
"@
    Add-Type -TypeDefinition $sqliteSource

    $backendProcess = Start-Process `
        -FilePath (Join-Path $sandboxDirectory 'BrickStack2Backend.exe') `
        -WorkingDirectory $sandboxDirectory `
        -WindowStyle Hidden -PassThru
    Wait-ForHealth 'http://127.0.0.1:8081/health' $backendProcess

    $uiProcess = Start-Process -FilePath $uiExecutable `
        -WorkingDirectory $projectRoot -WindowStyle Hidden -PassThru
    Wait-ForHealth 'http://127.0.0.1:8080/health' $uiProcess

    $databaseFile = Join-Path $sandboxDBase 'BrickStack.db'
    $users = Seed-TestUsers $databaseFile
    $uiBaseUrl = 'http://127.0.0.1:8080'
    $backendBaseUrl = 'http://127.0.0.1:8081'
    $sessionA = New-UserSession $users[0] $uiBaseUrl
    $sessionB = New-UserSession $users[1] $uiBaseUrl
    $unauthenticatedSession = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
    foreach ($baseUrl in @($uiBaseUrl, $backendBaseUrl)) {
        foreach ($route in @(
                '/api/collections',
                '/api/collections/1/set-lists',
                '/api/set-lists/1',
                '/api/set-lists/1/sets',
                '/api/collection-sets/1')) {
            Assert-Equal (Get-HttpStatus 'GET' "$baseUrl$route" `
                $unauthenticatedSession) 401 `
                "Unauthenticated request read $route through $baseUrl"
        }
    }

    $collectionA = Invoke-JsonApi 'POST' "$uiBaseUrl/api/collections" `
        $sessionA @{ name = 'Private Collection A' }
    $collectionB = Invoke-JsonApi 'POST' "$uiBaseUrl/api/collections" `
        $sessionB @{ name = 'Private Collection B' }

    $listA = Invoke-JsonApi 'GET' "$uiBaseUrl/api/collections" $sessionA
    $listB = Invoke-JsonApi 'GET' "$uiBaseUrl/api/collections" $sessionB
    Assert-Equal $listA.collections.Count 1 `
        'Owner A saw an unexpected collection count'
    Assert-Equal $listA.collections[0].id $collectionA.id `
        'Owner A collection list contained another owner''s collection'
    Assert-Equal $listB.collections.Count 1 `
        'Owner B saw an unexpected collection count'
    Assert-Equal $listB.collections[0].id $collectionB.id `
        'Owner B collection list contained another owner''s collection'

    foreach ($baseUrl in @($uiBaseUrl, $backendBaseUrl)) {
        Assert-Equal (Get-HttpStatus 'GET' `
            "$baseUrl/api/collections/$($collectionA.id)" $sessionB) 404 `
            "Owner B read Owner A's collection through $baseUrl"
        Assert-Equal (Get-HttpStatus 'PUT' `
            "$baseUrl/api/collections/$($collectionA.id)" $sessionB @{
                name = 'Attempted cross-owner rename'
            }) 404 "Owner B renamed Owner A's collection through $baseUrl"
    }

    $renamedA = Invoke-JsonApi 'PUT' `
        "$uiBaseUrl/api/collections/$($collectionA.id)" $sessionA @{
            name = 'Renamed Private Collection A'
        }
    Assert-Equal $renamedA.name 'Renamed Private Collection A' `
        'Owner A could not rename their own collection'
    Assert-Equal (Get-HttpStatus 'GET' `
        "$uiBaseUrl/api/collections/$($collectionA.id)" $sessionA) 200 `
        'Owner A could not read their own collection after rename'
    Assert-Equal (Get-HttpStatus 'PUT' `
        "$uiBaseUrl/api/collections/$($collectionA.id)" $sessionA @{
            name = 'Invalid Owner Spoof'
            ownerId = $collectionB.id
        }) 400 'Collection rename accepted an extra owner field'

    $setListA = Invoke-JsonApi 'POST' `
        "$uiBaseUrl/api/collections/$($collectionA.id)/set-lists" $sessionA @{
            name = 'Private Set List A'
            description = 'Owner A list'
            useInCollection = $true
        }
    $setListB = Invoke-JsonApi 'POST' `
        "$uiBaseUrl/api/collections/$($collectionB.id)/set-lists" $sessionB @{
            name = 'Private Set List B'
            description = 'Owner B list'
            useInCollection = $false
        }
    Assert-Equal (Get-HttpStatus 'POST' `
        "$uiBaseUrl/api/collections/$($collectionB.id)/set-lists" $sessionA @{
            name = 'Attempted cross-owner set list'
            description = ''
            useInCollection = $false
        }) 404 'Owner A created a set list in Owner B''s collection'
    $setListsA = Invoke-JsonApi 'GET' `
        "$uiBaseUrl/api/collections/$($collectionA.id)/set-lists" $sessionA
    Assert-Equal $setListsA.setLists.Count 1 `
        'Owner A saw an unexpected set-list count'
    Assert-Equal $setListsA.setLists[0].id $setListA.id `
        'Owner A saw another owner''s set list'
    foreach ($baseUrl in @($uiBaseUrl, $backendBaseUrl)) {
        Assert-Equal (Get-HttpStatus 'GET' `
            "$baseUrl/api/collections/$($collectionB.id)/set-lists" $sessionA) 404 `
            "Owner A listed Owner B's set lists through $baseUrl"
        Assert-Equal (Get-HttpStatus 'GET' `
            "$baseUrl/api/set-lists/$($setListB.id)" $sessionA) 404 `
            "Owner A read Owner B's set list through $baseUrl"
        Assert-Equal (Get-HttpStatus 'GET' `
            "$baseUrl/api/set-lists/$($setListB.id)/sets" $sessionA) 404 `
            "Owner A listed Owner B's set entries through $baseUrl"
        Assert-Equal (Get-HttpStatus 'PUT' `
            "$baseUrl/api/set-lists/$($setListB.id)" $sessionA @{
                name = 'Attempted cross-owner update'
                description = 'forbidden'
                useInCollection = $true
            }) 404 "Owner A updated Owner B's set list through $baseUrl"
        Assert-Equal (Get-HttpStatus 'DELETE' `
            "$baseUrl/api/set-lists/$($setListB.id)" $sessionA) 404 `
            "Owner A removed Owner B's set list through $baseUrl"
    }

    $setListA = Invoke-JsonApi 'PUT' `
        "$uiBaseUrl/api/set-lists/$($setListA.id)" $sessionA @{
            name = 'Updated Set List A'
            description = 'Updated by owner A'
            useInCollection = $true
        }
    foreach ($baseUrl in @($uiBaseUrl, $backendBaseUrl)) {
        Assert-Equal (Get-HttpStatus 'PUT' `
            "$baseUrl/api/set-lists/$($setListA.id)" $sessionA @{
                name = 'Rejected without CSRF'
                description = ''
                useInCollection = $false
            } $false) 403 "Set-list update skipped CSRF validation at $baseUrl"
    }
    Assert-Equal $setListA.name 'Updated Set List A' `
        'Owner A could not update their set list'
    $setA = Invoke-JsonApi 'POST' `
        "$uiBaseUrl/api/set-lists/$($setListA.id)/sets" $sessionA @{
            setNumber = '4200-1'
            built = $false
            haveSpareParts = $false
            notes = 'Needs building'
        }
    Assert-Equal (Get-HttpStatus 'POST' `
        "$uiBaseUrl/api/set-lists/$($setListA.id)/sets" $sessionB @{
            setNumber = '4200-1'
            built = $false
            haveSpareParts = $false
            notes = ''
        }) 404 'Owner B added a set to Owner A''s set list'
    Assert-Equal (Get-HttpStatus 'POST' `
        "$uiBaseUrl/api/set-lists/$($setListA.id)/sets" $sessionA @{
            setNumber = 'not-a-catalog-set'
            built = $false
            haveSpareParts = $false
            notes = ''
        }) 404 'A set absent from the Rebrickable catalog was accepted'
    foreach ($baseUrl in @($uiBaseUrl, $backendBaseUrl)) {
        Assert-Equal (Get-HttpStatus 'GET' `
            "$baseUrl/api/collection-sets/$($setA.id)" $sessionB) 404 `
            "Owner B read Owner A's set through $baseUrl"
        Assert-Equal (Get-HttpStatus 'PUT' `
            "$baseUrl/api/collection-sets/$($setA.id)" $sessionB @{
                built = $true
                haveSpareParts = $true
                notes = 'Attempted cross-owner update'
            }) 404 "Owner B updated Owner A's set through $baseUrl"
        Assert-Equal (Get-HttpStatus 'DELETE' `
            "$baseUrl/api/collection-sets/$($setA.id)" $sessionB) 404 `
            "Owner B removed Owner A's set through $baseUrl"
    }
    $setsA = Invoke-JsonApi 'GET' `
        "$uiBaseUrl/api/set-lists/$($setListA.id)/sets" $sessionA
    Assert-Equal $setsA.sets.Count 1 'Owner A did not see their added set'
    Assert-Equal $setsA.sets[0].setNumber '4200-1' `
        'Owner A set list returned the wrong set number'
    foreach ($baseUrl in @($uiBaseUrl, $backendBaseUrl)) {
        Assert-Equal (Get-HttpStatus 'DELETE' `
            "$baseUrl/api/collection-sets/$($setA.id)" $sessionA $null $false) 403 `
            "Set removal skipped CSRF validation at $baseUrl"
    }
    $setA = Invoke-JsonApi 'PUT' `
        "$uiBaseUrl/api/collection-sets/$($setA.id)" $sessionA @{
            built = $true
            haveSpareParts = $true
            notes = 'Built and checked'
        }
    Assert-Equal $setA.notes 'Built and checked' `
        'Owner A could not update their set notes'
    Assert-Equal (Get-HttpStatus 'DELETE' `
        "$uiBaseUrl/api/collection-sets/$($setA.id)" $sessionA) 200 `
        'Owner A could not remove their set'
    Assert-Equal (Get-HttpStatus 'DELETE' `
        "$uiBaseUrl/api/set-lists/$($setListA.id)" $sessionA) 200 `
        'Owner A could not remove their set list'

    Write-Host 'Authenticated collection ownership HTTP checks passed.'
}
finally {
    foreach ($process in @($uiProcess, $backendProcess)) {
        if ($null -ne $process) {
            $process.Refresh()
            if (-not $process.HasExited) {
                Stop-Process -Id $process.Id -ErrorAction SilentlyContinue
                Wait-Process -Id $process.Id -Timeout 5 -ErrorAction SilentlyContinue
            }
        }
    }
    if (Test-Path -LiteralPath $sandboxDirectory -PathType Container) {
        $resolvedSandbox = [System.IO.Path]::GetFullPath($sandboxDirectory)
        $resolvedOutput = [System.IO.Path]::GetFullPath($outputDirectory)
        if (-not $resolvedSandbox.StartsWith(
                $resolvedOutput + [System.IO.Path]::DirectorySeparatorChar,
                [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove unexpected test directory: $resolvedSandbox"
        }
        Remove-Item -LiteralPath $resolvedSandbox -Recurse -Force
    }
}

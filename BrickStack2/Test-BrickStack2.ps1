$ErrorActionPreference = 'Stop'

function Get-Json([string] $Uri) {
    return Invoke-RestMethod -Uri $Uri -Method Get -TimeoutSec 3
}

function Assert-Equal($Actual, $Expected, [string] $Description) {
    if ($Actual -ne $Expected) {
        throw "$Description. Expected '$Expected', got '$Actual'."
    }
}

function Assert-HttpStatus([string] $Uri, [int] $ExpectedStatus, [string] $Description) {
    try {
        $response = Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec 3
        $actualStatus = [int]$response.StatusCode
    }
    catch {
        if ($null -eq $_.Exception.Response) {
            throw "$Description. Request failed without an HTTP response: $($_.Exception.Message)"
        }
        $actualStatus = [int]$_.Exception.Response.StatusCode
    }
    Assert-Equal $actualStatus $ExpectedStatus $Description
}

function Assert-PostHttpStatus([string] $Uri, [string] $Body,
    [int] $ExpectedStatus, [string] $Description,
    [bool] $IncludeRequestHeader = $false) {
    $headers = @{}
    if ($IncludeRequestHeader) {
        $headers['X-BrickStack-Request'] = '1'
    }
    try {
        $response = Invoke-WebRequest -Uri $Uri -Method Post `
            -ContentType 'application/json' -Body $Body `
            -Headers $headers -UseBasicParsing -TimeoutSec 3
        $actualStatus = [int]$response.StatusCode
    }
    catch {
        if ($null -eq $_.Exception.Response) {
            throw "$Description. Request failed without an HTTP response: $($_.Exception.Message)"
        }
        $actualStatus = [int]$_.Exception.Response.StatusCode
    }
    Assert-Equal $actualStatus $ExpectedStatus $Description
}

function Assert-PutHttpStatus([string] $Uri, [string] $Body,
    [int] $ExpectedStatus, [string] $Description,
    [bool] $IncludeRequestHeader = $false) {
    $headers = @{}
    if ($IncludeRequestHeader) {
        $headers['X-BrickStack-Request'] = '1'
    }
    try {
        $response = Invoke-WebRequest -Uri $Uri -Method Put `
            -ContentType 'application/json' -Body $Body `
            -Headers $headers -UseBasicParsing -TimeoutSec 3
        $actualStatus = [int]$response.StatusCode
    }
    catch {
        if ($null -eq $_.Exception.Response) {
            throw "$Description. Request failed without an HTTP response: $($_.Exception.Message)"
        }
        $actualStatus = [int]$_.Exception.Response.StatusCode
    }
    Assert-Equal $actualStatus $ExpectedStatus $Description
}

function Assert-DeleteHttpStatus([string] $Uri, [int] $ExpectedStatus,
    [string] $Description, [bool] $IncludeRequestHeader = $false) {
    $headers = @{}
    if ($IncludeRequestHeader) {
        $headers['X-BrickStack-Request'] = '1'
    }
    try {
        $response = Invoke-WebRequest -Uri $Uri -Method Delete `
            -Headers $headers -UseBasicParsing -TimeoutSec 3
        $actualStatus = [int]$response.StatusCode
    }
    catch {
        if ($null -eq $_.Exception.Response) {
            throw
        }
        $actualStatus = [int]$_.Exception.Response.StatusCode
    }
    Assert-Equal $actualStatus $ExpectedStatus $Description
}

$backendHealth = Get-Json 'http://127.0.0.1:8081/health'
Assert-Equal $backendHealth.status 'ok' 'Backend health check failed'
Assert-Equal $backendHealth.service 'backend' 'Unexpected backend identity'

$databaseDirectory = Join-Path $PSScriptRoot 'Bin\Win64\Debug\DBase'
foreach ($databaseName in @('BrickStack.db', 'rb.db')) {
    $databasePath = Join-Path $databaseDirectory $databaseName
    if (-not (Test-Path -LiteralPath $databasePath -PathType Leaf)) {
        throw "Backend startup did not create or install the database: $databasePath"
    }
}

$uiHealth = Get-Json 'http://127.0.0.1:8080/health'
Assert-Equal $uiHealth.status 'ok' 'UI health check failed'
Assert-Equal $uiHealth.service 'ui' 'Unexpected UI identity'
$bootstrapStatus = Get-Json 'http://127.0.0.1:8080/api/auth/bootstrap/status'
if ($bootstrapStatus.required -isnot [bool]) {
    throw 'Admin bootstrap status did not return a Boolean required value.'
}
$authStatus = Get-Json 'http://127.0.0.1:8080/api/auth/session'
Assert-Equal $authStatus.authenticated $false 'A new browser session should be signed out'
Assert-HttpStatus 'http://127.0.0.1:8080/api/auth/login' 405 `
    'Login route accepted GET'
Assert-PostHttpStatus 'http://127.0.0.1:8080/api/auth/login' '{}' 403 `
    'Login route accepted a POST without the same-origin request header'
Assert-PostHttpStatus 'http://127.0.0.1:8081/api/auth/login' '{}' 403 `
    'Backend login route accepted a POST without the same-origin request header'
Assert-HttpStatus 'http://127.0.0.1:8080/api/auth/totp/enroll/start' 405 `
    'TOTP enrollment route accepted GET'
Assert-PostHttpStatus 'http://127.0.0.1:8080/api/auth/totp/enroll/start' '{}' 403 `
    'TOTP enrollment route accepted a POST without the same-origin request header'
Assert-PostHttpStatus 'http://127.0.0.1:8081/api/auth/totp/enroll/confirm' '{}' 403 `
    'Backend TOTP confirmation accepted a POST without the same-origin request header'
Assert-PostHttpStatus 'http://127.0.0.1:8080/api/auth/logout' '{}' 403 `
    'Logout route accepted a POST without the same-origin request header'
Assert-HttpStatus 'http://127.0.0.1:8080/api/auth/password' 405 `
    'Invitation password route accepted GET'
Assert-PostHttpStatus 'http://127.0.0.1:8080/api/auth/password' '{}' 403 `
    'Invitation password route accepted a POST without the same-origin request header'
$invalidInvitePasswordBody = @{
    username = 'unknown-invited-user'
    currentPassword = 'not-a-temporary-password'
    newPassword = 'A-valid-but-unused-test-password'
} | ConvertTo-Json -Compress
Assert-PostHttpStatus 'http://127.0.0.1:8080/api/auth/password' `
    $invalidInvitePasswordBody 401 `
    'Invitation password route did not safely reject invalid credentials' $true
Assert-PostHttpStatus 'http://127.0.0.1:8081/api/auth/password' '{}' 403 `
    'Backend invitation password route accepted a POST without the same-origin request header'
Assert-HttpStatus 'http://127.0.0.1:8080/api/admin/users' 401 `
    'Account list was exposed without authentication'
Assert-HttpStatus 'http://127.0.0.1:8081/api/admin/users' 401 `
    'Backend account list was exposed without authentication'
Assert-PostHttpStatus 'http://127.0.0.1:8080/api/admin/users' '{}' 403 `
    'Account creation accepted a POST without the same-origin request header'
Assert-HttpStatus 'http://127.0.0.1:8080/api/collections' 401 `
    'Collection list was exposed without authentication'
Assert-HttpStatus 'http://127.0.0.1:8081/api/collections' 401 `
    'Backend collection list was exposed without authentication'
Assert-HttpStatus 'http://127.0.0.1:8080/api/collections/1' 401 `
    'Collection detail was exposed without authentication'
Assert-HttpStatus 'http://127.0.0.1:8081/api/collections/1' 401 `
    'Backend collection detail was exposed without authentication'
Assert-HttpStatus 'http://127.0.0.1:8080/api/collections/1/set-lists' 401 `
    'Collection set lists were exposed without authentication'
Assert-HttpStatus 'http://127.0.0.1:8081/api/collections/1/set-lists' 401 `
    'Backend collection set lists were exposed without authentication'
Assert-HttpStatus 'http://127.0.0.1:8080/api/set-lists/1' 401 `
    'Set-list detail was exposed without authentication'
Assert-HttpStatus 'http://127.0.0.1:8081/api/set-lists/1' 401 `
    'Backend set-list detail was exposed without authentication'
Assert-HttpStatus 'http://127.0.0.1:8080/api/set-lists/1/sets' 401 `
    'Collection sets were exposed without authentication'
Assert-HttpStatus 'http://127.0.0.1:8081/api/set-lists/1/sets' 401 `
    'Backend collection sets were exposed without authentication'
Assert-HttpStatus 'http://127.0.0.1:8080/api/collection-sets/1' 401 `
    'Collection-set detail was exposed without authentication'
Assert-HttpStatus 'http://127.0.0.1:8081/api/collection-sets/1' 401 `
    'Backend collection-set detail was exposed without authentication'
Assert-PostHttpStatus 'http://127.0.0.1:8080/api/collections/1/set-lists' '{}' 403 `
    'Set-list creation accepted a POST without the same-origin request header'
Assert-PostHttpStatus 'http://127.0.0.1:8081/api/collections/1/set-lists' '{}' 401 `
    'Backend set-list creation was accessible without authentication'
Assert-PutHttpStatus 'http://127.0.0.1:8080/api/set-lists/1' '{}' 403 `
    'Set-list update accepted a PUT without the same-origin request header'
Assert-PutHttpStatus 'http://127.0.0.1:8081/api/set-lists/1' '{}' 401 `
    'Backend set-list update was accessible without authentication'
Assert-PostHttpStatus 'http://127.0.0.1:8080/api/set-lists/1/sets' '{}' 403 `
    'Set addition accepted a POST without the same-origin request header'
Assert-PostHttpStatus 'http://127.0.0.1:8081/api/set-lists/1/sets' '{}' 401 `
    'Backend set addition was accessible without authentication'
Assert-PutHttpStatus 'http://127.0.0.1:8080/api/collection-sets/1' '{}' 403 `
    'Set update accepted a PUT without the same-origin request header'
Assert-PutHttpStatus 'http://127.0.0.1:8081/api/collection-sets/1' '{}' 401 `
    'Backend set update was accessible without authentication'
Assert-DeleteHttpStatus 'http://127.0.0.1:8080/api/set-lists/1' 403 `
    'Set-list removal accepted DELETE without the same-origin request header'
Assert-DeleteHttpStatus 'http://127.0.0.1:8081/api/set-lists/1' 401 `
    'Backend set-list removal was accessible without authentication'
Assert-DeleteHttpStatus 'http://127.0.0.1:8080/api/collection-sets/1' 403 `
    'Set removal accepted DELETE without the same-origin request header'
Assert-DeleteHttpStatus 'http://127.0.0.1:8081/api/collection-sets/1' 401 `
    'Backend set removal was accessible without authentication'
foreach ($baseUrl in @('http://127.0.0.1:8080', 'http://127.0.0.1:8081')) {
    foreach ($route in @(
            '/api/collections/1/part-lists',
            '/api/part-lists/1',
            '/api/part-lists/1/parts',
            '/api/loose-parts/1')) {
        Assert-HttpStatus "$baseUrl$route" 401 `
            "Unauthenticated request read $route through $baseUrl"
    }
}
Assert-PostHttpStatus 'http://127.0.0.1:8080/api/collections/1/part-lists' '{}' 403 `
    'Part-list creation accepted a POST without the same-origin request header'
Assert-PostHttpStatus 'http://127.0.0.1:8081/api/collections/1/part-lists' '{}' 401 `
    'Backend part-list creation was accessible without authentication'
Assert-PostHttpStatus 'http://127.0.0.1:8080/api/part-lists/1/parts' '{}' 403 `
    'Loose-part addition accepted a POST without the same-origin request header'
Assert-PostHttpStatus 'http://127.0.0.1:8081/api/part-lists/1/parts' '{}' 401 `
    'Backend loose-part addition was accessible without authentication'
Assert-PutHttpStatus 'http://127.0.0.1:8080/api/part-lists/1' '{}' 403 `
    'Part-list update accepted a PUT without the same-origin request header'
Assert-PutHttpStatus 'http://127.0.0.1:8081/api/part-lists/1' '{}' 401 `
    'Backend part-list update was accessible without authentication'
Assert-PutHttpStatus 'http://127.0.0.1:8080/api/loose-parts/1' '{}' 403 `
    'Loose-part update accepted a PUT without the same-origin request header'
Assert-PutHttpStatus 'http://127.0.0.1:8081/api/loose-parts/1' '{}' 401 `
    'Backend loose-part update was accessible without authentication'
Assert-DeleteHttpStatus 'http://127.0.0.1:8080/api/part-lists/1' 403 `
    'Part-list removal accepted DELETE without the same-origin request header'
Assert-DeleteHttpStatus 'http://127.0.0.1:8081/api/part-lists/1' 401 `
    'Backend part-list removal was accessible without authentication'
Assert-DeleteHttpStatus 'http://127.0.0.1:8080/api/loose-parts/1' 403 `
    'Loose-part removal accepted DELETE without the same-origin request header'
Assert-DeleteHttpStatus 'http://127.0.0.1:8081/api/loose-parts/1' 401 `
    'Backend loose-part removal was accessible without authentication'
Assert-PostHttpStatus 'http://127.0.0.1:8080/api/collections' '{}' 403 `
    'Collection creation accepted a POST without the same-origin request header'
Assert-PostHttpStatus 'http://127.0.0.1:8081/api/collections' '{}' 401 `
    'Backend collection creation was accessible without authentication'
$spoofedCollectionBody = @{
    name = 'Spoofed collection'
    userId = 1
    ownerId = 1
} | ConvertTo-Json -Compress
Assert-PostHttpStatus 'http://127.0.0.1:8080/api/collections' `
    $spoofedCollectionBody 401 `
    'Collection creation was allowed without an authenticated owner' $true
Assert-PostHttpStatus 'http://127.0.0.1:8081/api/collections' `
    $spoofedCollectionBody 401 `
    'Backend collection creation was allowed without an authenticated owner' $true
Assert-PutHttpStatus 'http://127.0.0.1:8080/api/collections/1' `
    '{"name":"Updated name"}' 403 `
    'Collection rename accepted a PUT without the same-origin request header'
Assert-PutHttpStatus 'http://127.0.0.1:8081/api/collections/1' `
    '{"name":"Updated name"}' 401 `
    'Backend collection rename was accessible without authentication'
Assert-PutHttpStatus 'http://127.0.0.1:8080/api/collections/1' `
    '{"name":"Updated name"}' 401 `
    'Collection rename was accessible without authentication' $true
Assert-PutHttpStatus 'http://127.0.0.1:8081/api/collections/1' `
    '{"name":"Updated name"}' 401 `
    'Backend collection rename was accessible without authentication' $true
Assert-HttpStatus 'http://127.0.0.1:8080/api/auth/bootstrap/password' 405 `
    'Bootstrap password route accepted GET'
Assert-PostHttpStatus 'http://127.0.0.1:8080/api/auth/bootstrap/password' '{' 400 `
    'Bootstrap password route accepted malformed JSON' $true
$invalidBootstrapBody = @{
    username = 'Admin'
    currentPassword = 'not-the-temporary-password'
    newPassword = 'A-valid-but-unused-test-password'
} | ConvertTo-Json -Compress
Assert-PostHttpStatus 'http://127.0.0.1:8081/api/auth/bootstrap/password' `
    $invalidBootstrapBody 401 'Backend did not identify rejected bootstrap credentials' $true
Assert-PostHttpStatus 'http://127.0.0.1:8080/api/auth/bootstrap/password' `
    $invalidBootstrapBody 401 'UI proxy did not preserve rejected bootstrap credentials' $true

$catalogSummary = Get-Json 'http://127.0.0.1:8080/api/catalog/summary'
if (($catalogSummary.sets -lt 1) -or ($catalogSummary.parts -lt 1) -or
    ($catalogSummary.themes -lt 1)) {
    throw 'Catalog summary did not return non-zero catalog totals.'
}

$backendData = Get-Json 'http://127.0.0.1:8081/api/demo'
Assert-Equal $backendData.service 'BrickStack2 backend' 'Unexpected backend data source'

$backendCatalog = Get-Json 'http://127.0.0.1:8081/api/catalog/sets?pageSize=2'
$uiCatalog = Get-Json 'http://127.0.0.1:8080/api/catalog/sets?pageSize=2'
Assert-Equal $backendCatalog.items.Count 2 'Backend catalog page size was not applied'
Assert-Equal $uiCatalog.items.Count 2 'UI server did not proxy catalog results'
if (-not $backendCatalog.hasMore -or -not $backendCatalog.nextCursor) {
    throw 'The catalog page did not return a usable keyset pagination cursor.'
}

$setNumber = [uri]::EscapeDataString($backendCatalog.items[0].setNumber)
$setDetails = Get-Json "http://127.0.0.1:8080/api/catalog/sets/$setNumber"
Assert-Equal $setDetails.setNumber $backendCatalog.items[0].setNumber 'Catalog set details did not match the selected set'
$knownSet = Get-Json 'http://127.0.0.1:8080/api/catalog/sets/4200-1'
$filteredSets = Get-Json "http://127.0.0.1:8080/api/catalog/sets?themeId=$($knownSet.themeId)&year=$($knownSet.year)&pageSize=100"
if (-not ($filteredSets.items | Where-Object { $_.setNumber -eq '4200-1' })) {
    throw 'Set search did not apply the selected theme and year filters.'
}
$backendInventoryPage = Get-Json 'http://127.0.0.1:8081/api/catalog/sets/4200-1/inventory?pageSize=2'
$inventoryPage = Get-Json 'http://127.0.0.1:8080/api/catalog/sets/4200-1/inventory?pageSize=2'
Assert-Equal $backendInventoryPage.items.Count 2 'Backend set inventory page size was not applied'
Assert-Equal $inventoryPage.setNumber '4200-1' 'Set inventory route returned the wrong set'
Assert-Equal $inventoryPage.version 1 'Set inventory did not select the expected inventory version'
Assert-Equal $inventoryPage.items.Count 2 'Set inventory page size was not applied'
if (-not $inventoryPage.hasMore -or -not $inventoryPage.nextCursor) {
    throw 'Set inventory pagination did not return a cursor.'
}
$inventoryCursor = [uri]::EscapeDataString($inventoryPage.nextCursor)
$nextInventoryPage = Get-Json "http://127.0.0.1:8080/api/catalog/sets/4200-1/inventory?pageSize=2&version=$($inventoryPage.version)&cursor=$inventoryCursor"
Assert-Equal $nextInventoryPage.items.Count 2 'Set inventory cursor was not applied'
$backendParts = Get-Json 'http://127.0.0.1:8081/api/catalog/parts?pageSize=2'
$uiParts = Get-Json 'http://127.0.0.1:8080/api/catalog/parts?pageSize=2'
Assert-Equal $backendParts.items.Count 2 'Backend part page size was not applied'
Assert-Equal $uiParts.items.Count 2 'UI server did not proxy part results'
$partNumber = [uri]::EscapeDataString($backendParts.items[0].partNumber)
$partDetails = Get-Json "http://127.0.0.1:8080/api/catalog/parts/$partNumber"
Assert-Equal $partDetails.partNumber $backendParts.items[0].partNumber 'Catalog part details did not match the selected part'
$themes = Get-Json 'http://127.0.0.1:8080/api/catalog/themes'
if ($themes.Count -eq 0) {
    throw 'The catalog theme lookup returned no entries.'
}
Assert-HttpStatus 'http://127.0.0.1:8081/api/catalog/sets?pageSize=101' 400 'Backend accepted an out-of-range page size'
Assert-HttpStatus 'http://127.0.0.1:8080/api/catalog/sets?pageSize=101' 400 'UI proxy did not preserve backend validation status'
Assert-HttpStatus 'http://127.0.0.1:8080/api/catalog/sets/4200-1/inventory?pageSize=101' 400 'UI proxy did not validate inventory page size'
Assert-HttpStatus 'http://127.0.0.1:8080/api/catalog/sets/4200-1/inventory?cursor=invalid-cursor' 400 'Malformed inventory cursor was not rejected'
Assert-HttpStatus 'http://127.0.0.1:8081/api/catalog/sets/not-a-real-set' 404 'Backend did not return not-found for an unknown set'
Assert-HttpStatus 'http://127.0.0.1:8080/api/catalog/parts/not-a-real-part' 404 'UI proxy did not preserve backend not-found status'
Assert-HttpStatus 'http://127.0.0.1:8080/api/catalog/unknown' 404 'UI proxy forwarded a route outside its allowlist'

$page = Invoke-WebRequest -Uri 'http://127.0.0.1:8080/' -UseBasicParsing -TimeoutSec 3
Assert-Equal $page.StatusCode 200 'UI page request failed'
if (($page.Content -notmatch 'id="page-heading">Overview</h1>') -or
    ($page.Content -notmatch 'admin-bootstrap') -or
    ($page.Content -notmatch 'id="overview-page"') -or
    ($page.Content -notmatch 'id="catalog-page"') -or
    ($page.Content -notmatch 'data-page="sets"') -or
    ($page.Content -notmatch 'data-page="parts"') -or
    ($page.Content -match 'id="sets-tab"|id="parts-tab"') -or
    ($page.Content -notmatch 'profile-button') -or
    ($page.Content -notmatch 'create-user-form') -or
    ($page.Content -notmatch 'invite-password-form') -or
    ($page.Content -notmatch 'Browse sets') -or
    ($page.Content -notmatch 'id="set-theme"') -or
    ($page.Content -notmatch 'id="set-year"') -or
    ($page.Content -notmatch 'id="login-totp-code"') -or
    ($page.Content -notmatch 'id="totp-enrollment"') -or
    ($page.Content -notmatch 'Search parts') -or
    ($page.Content -match 'DEMO DATA')) {
    throw 'The served page did not contain the real catalog browser UI.'
}

$styles = Invoke-WebRequest -Uri 'http://127.0.0.1:8080/app.css' -UseBasicParsing -TimeoutSec 3
Assert-Equal $styles.StatusCode 200 'UI stylesheet request failed'
if ($styles.Content -notmatch '--blue: #2958cd') {
    throw 'The served stylesheet did not contain the BrickStack design tokens.'
}

$script = Invoke-WebRequest -Uri 'http://127.0.0.1:8080/app.js' -UseBasicParsing -TimeoutSec 3
Assert-Equal $script.StatusCode 200 'UI script request failed'
if (($script.Content -notmatch '/api/catalog/summary') -or
    ($script.Content -notmatch '/api/auth/bootstrap/status') -or
    ($script.Content -notmatch '/api/auth/bootstrap/password') -or
    ($script.Content -notmatch '/api/auth/password') -or
    ($script.Content -notmatch '/api/auth/totp/enroll/start') -or
    ($script.Content -notmatch '/api/auth/totp/enroll/confirm') -or
    ($script.Content -notmatch '/api/admin/users') -or
    ($script.Content -notmatch '/api/catalog/\$\{mode\}') -or
    ($script.Content -notmatch "params.set\('themeId'") -or
    ($script.Content -notmatch "params.set\('year'") -or
    ($script.Content -notmatch '/api/catalog/\$\{route\}/') -or
    ($script.Content -notmatch '/inventory\?\$\{params\}') -or
    ($script.Content -notmatch 'Set inventory')) {
    throw 'The browser script did not load catalog counts, search, details, and set inventory.'
}

Write-Host 'BrickStack2 HTTP smoke checks passed.'

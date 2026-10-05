$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
$backendPath = Join-Path $root 'Bin\Win64\Debug\BrickStack2Backend.exe'
$uiPath = Join-Path $root 'Bin\Win64\Debug\BrickStack2UI.exe'

function Wait-ForService([string] $Uri) {
    $deadline = [DateTime]::UtcNow.AddSeconds(10)
    while ([DateTime]::UtcNow -lt $deadline) {
        try {
            Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec 1 | Out-Null
            return
        }
        catch {
            Start-Sleep -Milliseconds 200
        }
    }

    throw "Timed out waiting for service: $Uri"
}

function Test-Service([string] $Uri) {
    try {
        Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec 1 | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

if (-not (Test-Path $backendPath)) {
    throw "Backend executable not found. Build Src\Backend\BrickStack2Backend.dproj first."
}
if (-not (Test-Path $uiPath)) {
    throw "UI executable not found. Build Src\UI\BrickStack2UI.dproj first."
}

$backendHealth = 'http://127.0.0.1:8081/health'
if (-not (Test-Service $backendHealth)) {
    Start-Process -FilePath $backendPath -WorkingDirectory $root | Out-Null
    Wait-ForService $backendHealth
}

$uiHealth = 'http://127.0.0.1:8080/health'
if (-not (Test-Service $uiHealth)) {
    Start-Process -FilePath $uiPath -WorkingDirectory $root | Out-Null
    Wait-ForService $uiHealth
}

Write-Host 'BrickStack2 is running at http://127.0.0.1:8080'
Write-Host 'The UI and backend run in separate console windows.'
Write-Host 'Press Ctrl+C in either service window to stop only that service.'
Start-Process 'http://127.0.0.1:8080'

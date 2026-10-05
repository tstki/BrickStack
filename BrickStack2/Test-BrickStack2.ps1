$ErrorActionPreference = 'Stop'

function Get-Json([string] $Uri) {
    return Invoke-RestMethod -Uri $Uri -Method Get -TimeoutSec 3
}

function Assert-Equal($Actual, $Expected, [string] $Description) {
    if ($Actual -ne $Expected) {
        throw "$Description. Expected '$Expected', got '$Actual'."
    }
}

$backendHealth = Get-Json 'http://127.0.0.1:8081/health'
Assert-Equal $backendHealth.status 'ok' 'Backend health check failed'
Assert-Equal $backendHealth.service 'backend' 'Unexpected backend identity'

$uiHealth = Get-Json 'http://127.0.0.1:8080/health'
Assert-Equal $uiHealth.status 'ok' 'UI health check failed'
Assert-Equal $uiHealth.service 'ui' 'Unexpected UI identity'

$backendData = Get-Json 'http://127.0.0.1:8081/api/demo'
$uiData = Get-Json 'http://127.0.0.1:8080/api/demo'
Assert-Equal $backendData.service 'BrickStack2 backend' 'Unexpected backend data source'
Assert-Equal $uiData.collection.sets 128 'UI server did not return backend data'
Assert-Equal $uiData.setLists.Count 3 'Unexpected demo set-list count'

$page = Invoke-WebRequest -Uri 'http://127.0.0.1:8080/' -UseBasicParsing -TimeoutSec 3
Assert-Equal $page.StatusCode 200 'UI page request failed'
if ($page.Content -notmatch 'Your collection') {
    throw 'The served page did not contain the BrickStack2 demo UI.'
}

$styles = Invoke-WebRequest -Uri 'http://127.0.0.1:8080/app.css' -UseBasicParsing -TimeoutSec 3
Assert-Equal $styles.StatusCode 200 'UI stylesheet request failed'
if ($styles.Content -notmatch '--blue: #2958cd') {
    throw 'The served stylesheet did not contain the BrickStack design tokens.'
}

$script = Invoke-WebRequest -Uri 'http://127.0.0.1:8080/app.js' -UseBasicParsing -TimeoutSec 3
Assert-Equal $script.StatusCode 200 'UI script request failed'
if ($script.Content -notmatch "fetch\('/api/demo'") {
    throw 'The browser script did not request demo data from the UI server.'
}

Write-Host 'BrickStack2 HTTP smoke checks passed.'

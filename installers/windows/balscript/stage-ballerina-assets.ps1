param(
    [Parameter(Mandatory = $true)]
    [string]$AssetsDir
)

$ErrorActionPreference = 'Stop'
Add-Type -A 'System.IO.Compression.FileSystem'

$ballerinaTarget = '.\WixPackage\payload\Integrator\components\ballerina'
$binTarget = Join-Path $ballerinaTarget 'bin'
$updatesTarget = Join-Path $ballerinaTarget 'updates'
$repoBalaTarget = Join-Path $ballerinaTarget 'repo\bala'
$resourcesTarget = Join-Path $ballerinaTarget 'resources'
$updateToolTemp = 'C:\tmp_wso2update_tool'
$updatesExtractDir = 'C:\tmp_bal_updates'

New-Item -ItemType Directory -Force -Path $binTarget, $updatesTarget, $repoBalaTarget, $resourcesTarget | Out-Null

Copy-Item -Force (Join-Path $AssetsDir 'LICENSE') (Join-Path $ballerinaTarget 'LICENSE')
Copy-Item -Force (Join-Path $AssetsDir 'update_tool_setup.ps1') (Join-Path $binTarget 'update_tool_setup.ps1')

$updateToolZip = Join-Path $AssetsDir 'wso2update-tool-0.0.1.zip'
if (-not (Test-Path $updateToolZip)) {
    throw "WSO2 update tool package not found: $updateToolZip"
}

Remove-Item -Recurse -Force $updateToolTemp -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $updateToolTemp | Out-Null
[IO.Compression.ZipFile]::ExtractToDirectory($updateToolZip, $updateToolTemp)

$updateToolBala = Join-Path $updateToolTemp 'bala'
if (-not (Test-Path $updateToolBala)) {
    throw 'WSO2 update tool package is missing the bala directory'
}

Copy-Item -Path (Join-Path $updateToolBala '*') -Destination $repoBalaTarget -Recurse -Force

$balToolsToml = Join-Path $resourcesTarget 'bal-tools.toml'
if (-not (Test-Path $balToolsToml)) {
    New-Item -ItemType File -Force -Path $balToolsToml | Out-Null
}

if (-not (Select-String -Path $balToolsToml -Pattern 'id = "wso2update"' -Quiet)) {
    Add-Content -Path $balToolsToml -Value @"

[[tool]]
id = "wso2update"
org = "ballerina"
name = "tool.wso2update"
version = "0.0.1"
active = true
"@
}

Remove-Item -Recurse -Force $updateToolTemp -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force $updatesExtractDir -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $updatesExtractDir | Out-Null
[IO.Compression.ZipFile]::ExtractToDirectory((Join-Path $AssetsDir 'updates.zip'), $updatesExtractDir)

$updatesRoot = Join-Path $updatesExtractDir 'updates'
if (Test-Path $updatesRoot) {
    Copy-Item -Path (Join-Path $updatesRoot '*') -Destination $updatesTarget -Recurse -Force
} else {
    Copy-Item -Path (Join-Path $updatesExtractDir '*') -Destination $updatesTarget -Recurse -Force
}

Remove-Item -Recurse -Force $updatesExtractDir

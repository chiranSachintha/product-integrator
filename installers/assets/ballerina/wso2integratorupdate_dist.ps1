$ErrorActionPreference = "Stop"

function Is-Numeric([string]$Value) {
    return $Value -match '^\d+$'
}

function Strip-ArchiveExtension([string]$FileName) {
    if ($FileName.EndsWith('.bala')) {
        return $FileName.Substring(0, $FileName.Length - 5)
    }
    if ($FileName.EndsWith('.zip')) {
        return $FileName.Substring(0, $FileName.Length - 4)
    }
    return $FileName
}

function Get-TargetDirectoryName([string]$FileName) {
    $baseName = Strip-ArchiveExtension $FileName
    $parts = $baseName.Split('.')
    if ($parts.Length -eq 4 -and (Is-Numeric $parts[0]) -and (Is-Numeric $parts[1]) -and (Is-Numeric $parts[2]) -and (Is-Numeric $parts[3])) {
        return "$($parts[0]).$($parts[1]).$($parts[2])"
    }
    return $baseName
}

function Get-UpdateToolBinary([string]$BinDir) {
    if (-not (Test-Path -LiteralPath $BinDir)) {
        return $null
    }

    return Get-ChildItem -LiteralPath $BinDir -File |
        Where-Object { $_.Name.StartsWith('wso2update_') -and $_.Extension -ne '.sh' -and $_.Extension -ne '.ps1' } |
        Sort-Object { $_.Name } -Descending |
        Select-Object -First 1
}

function Run-SetupScript([string]$BinDir) {
    $setupScript = Join-Path $BinDir 'update_tool_setup.ps1'
    if (-not (Test-Path -LiteralPath $setupScript)) {
        return
    }

    & powershell -nologo -noprofile -ExecutionPolicy Bypass -File $setupScript
    if ($LASTEXITCODE -ne 0) {
        throw "failed to execute $setupScript"
    }
}

function Extract-Archive([string]$ArchivePath, [string]$DestinationDir) {
    $archiveParent = Split-Path -Parent $ArchivePath
    $targetDirectoryName = Get-TargetDirectoryName (Split-Path -Leaf $ArchivePath)
    $extractedDir = Join-Path $archiveParent $targetDirectoryName
    $tempDir = Join-Path $archiveParent ('.wso2update_' + [System.Guid]::NewGuid().ToString('N'))
    $extractSource = $ArchivePath
    $tempZipPath = $null

    New-Item -ItemType Directory -Path $tempDir | Out-Null

    if ($ArchivePath.EndsWith('.bala')) {
        $tempZipPath = Join-Path $archiveParent ([System.IO.Path]::GetFileNameWithoutExtension($ArchivePath) + '.zip')
        Copy-Item -LiteralPath $ArchivePath -Destination $tempZipPath -Force
        $extractSource = $tempZipPath
    }

    Expand-Archive -LiteralPath $extractSource -DestinationPath $tempDir -Force

    $sourceRoot = Get-ChildItem -LiteralPath $tempDir -Force -Directory |
        Where-Object { $_.Name -ne '__MACOSX' } |
        Select-Object -First 1
    if ($null -eq $sourceRoot) {
        $sourceRoot = Get-Item -LiteralPath $tempDir
    }

    if (Test-Path -LiteralPath $extractedDir) {
        Remove-Item -LiteralPath $extractedDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $extractedDir | Out-Null

    Copy-Item -Path (Join-Path $sourceRoot.FullName '*') -Destination $extractedDir -Recurse -Force
    Get-ChildItem -LiteralPath $extractedDir -Recurse -Force |
        Where-Object { $_.Name -eq '__MACOSX' -or $_.Name -like '._*' } |
        Remove-Item -Recurse -Force

    Remove-Item -LiteralPath $ArchivePath -Force
    if ($null -ne $tempZipPath -and (Test-Path -LiteralPath $tempZipPath)) {
        Remove-Item -LiteralPath $tempZipPath -Force
    }
    Remove-Item -LiteralPath $tempDir -Recurse -Force
}

function Extract-RepoArchives([string]$RepoDir) {
    if (-not (Test-Path -LiteralPath $RepoDir)) {
        return
    }

    Get-ChildItem -LiteralPath $RepoDir -Recurse -File |
        Where-Object { $_.Extension -eq '.zip' -or $_.Extension -eq '.bala' } |
        ForEach-Object {
            Extract-Archive $_.FullName (Split-Path -Parent $_.FullName)
        }
}

function Print-Help {
    @'
wso2integratorupdate_dist tool is a simple command-line tool that connects to the
WSO2 Update service, determines which updates are new and relevant, and
downloads them and updates the product.

To find out the latest on WSO2 Update, visit https://wso2.com/updates

Usage:
  wso2integratorupdate_dist [flags]
  wso2integratorupdate_dist [command]

Examples:
# Check the current version of Update tool in use on your system
  wso2integratorupdate_dist version

# Get help on how to use the update command
  wso2integratorupdate_dist help check

# Update the product to the latest level. You will be prompted to enter WSO2 credentials.
  wso2integratorupdate_dist
  Username: user@wso2.com
  Password for ‘user@wso2.com’: my_password

# Update the product to the latest level by entering WSO2 credentials as arguments.
  wso2integratorupdate_dist --username user@wso2.com --password my_password

# Update the product up to a given level
  wso2integratorupdate_dist --level 3.0.0.10

# Simulate the update
  wso2integratorupdate_dist --dry-run

Available Commands:
  apply-hotfix  Apply an available hotfix.
  apply-update  Apply created update zip file on to the product
  check         Check available new levels for the product
  completion    Generate the autocompletion script for the specified shell
  create-docker Create Docker image of the product
  create-update Create update zip file for the product
  current-state Show current details of the product.
  help          Help about any command
  revert-hotfix Revert most recently applied hotfix.
  version       Print the Update tool version information.

Flags:
  -b, --backup string     Specify updates backup directory
  -c, --channel string    Channel updates should be downloaded from (default "full")
      --continue          Merge resolved conflicts
      --dry-run           Simulate the update
  -h, --help              help for wso2integratorupdate_dist
  -l, --level string      Level in which the product should be updated to
      --no-backup         Skip product backup
  -p, --password string   Specify your WSO2 account password
      --revert            Revert to the previous update level
      --template string   Specify the template output
  -u, --username string   Specify your WSO2 account email
  -v, --verbose           Enable verbose mode

Use "wso2integratorupdate_dist [command] --help" for more information about a command.
'@
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$binDir = $scriptDir
$setupScript = Join-Path $binDir 'update_tool_setup.ps1'
if (-not (Test-Path -LiteralPath $setupScript)) {
    Write-Error "update_tool_setup.ps1 not found in $binDir"
    exit 1
}

$helpArgs = @('-h', '--help', 'help')
if ($helpArgs -contains $args[0]) {
    Print-Help
    exit 0
}

$updateTool = Get-UpdateToolBinary $binDir
if ($null -eq $updateTool) {
    Run-SetupScript $binDir
    $updateTool = Get-UpdateToolBinary $binDir
    if ($null -eq $updateTool) {
        Write-Error "ballerina: WSO2 update tool is not available in '$binDir'."
        Write-Error "Run '$setupScript' first."
        exit 1
    }
}

& $updateTool.FullName @args
$exitCode = $LASTEXITCODE
if ($exitCode -eq 0) {
    Extract-RepoArchives (Join-Path (Split-Path -Parent $binDir) 'repo')
}

exit $exitCode

REM Accepts six arguments: ballerina.zip, ballerina-version, integrator.zip, ICP.zip, jre.zip, and version
REM Extracts the zip files to their respective payload directories and applies the version to Package.wxs before building the installer

@echo off
setlocal

REM Check for required arguments
if "%~1"=="" (
    echo Usage: build.bat ^<path-to-ballerina.zip^> ^<ballerina-version^> ^<path-to-integrator.zip^> ^<path-to-ICP.zip^> ^<path-to-jre.zip^> ^<version^>
    exit /b 1
)
if "%~2"=="" (
    echo Usage: build.bat ^<path-to-ballerina.zip^> ^<ballerina-version^> ^<path-to-integrator.zip^> ^<path-to-ICP.zip^> ^<path-to-jre.zip^> ^<version^>
    exit /b 1
)

if "%~3"=="" (
    echo Usage: build.bat ^<path-to-ballerina.zip^> ^<ballerina-version^> ^<path-to-integrator.zip^> ^<path-to-ICP.zip^> ^<path-to-jre.zip^> ^<version^>
    exit /b 1
)

if "%~4"=="" (
    echo Usage: build.bat ^<path-to-ballerina.zip^> ^<ballerina-version^> ^<path-to-integrator.zip^> ^<path-to-ICP.zip^> ^<path-to-jre.zip^> ^<version^>
    exit /b 1
)

if "%~5"=="" (
    echo Usage: build.bat ^<path-to-ballerina.zip^> ^<ballerina-version^> ^<path-to-integrator.zip^> ^<path-to-ICP.zip^> ^<path-to-jre.zip^> ^<version^>
    exit /b 1
)

if "%~6"=="" (
    echo Usage: build.bat ^<path-to-ballerina.zip^> ^<ballerina-version^> ^<path-to-integrator.zip^> ^<path-to-ICP.zip^> ^<path-to-jre.zip^> ^<version^>
    exit /b 1
)

set "BALLERINA_ASSETS_DIR=%~dp0..\assets\ballerina"
set "ICP_ASSETS_DIR=%~dp0..\assets\icp"

REM Clean up any leftover payload directory from a previous build
if exist ".\WixPackage\payload" rmdir /s /q ".\WixPackage\payload"

REM Clean the WiX intermediate output before each build. The WiX SDK hard-links
REM obj\...\WSO2-Integrator.msi to bin, and build.bat renames the bin entry to the
REM final wso2-integrator-<v>[-update].msi (still the same inode). When the second
REM profile (editor-update) rebuilds, WiX overwrites obj\WSO2-Integrator.msi in place
REM on that shared inode, clobbering the already-renamed full MSI so both profiles end
REM up byte-identical. Removing obj forces a fresh inode per build; the previously
REM renamed *.msi keeps its own inode/content. Only the un-renamed WSO2-Integrator.msi
REM is deleted from bin so a prior profile's renamed output is preserved.
if exist ".\WixPackage\obj" rmdir /s /q ".\WixPackage\obj"
if exist ".\WixPackage\bin\x64\Release\en-US\WSO2-Integrator.msi" del /q ".\WixPackage\bin\x64\Release\en-US\WSO2-Integrator.msi"

@REM REM Extract integrator.zip
powershell -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::ExtractToDirectory('%~3', '.\WixPackage\payload\Integrator'); }"
if errorlevel 1 (
    echo Integrator extraction failed
    exit /b 1
)
powershell -nologo -noprofile -command "& { New-Item -ItemType Directory -Force -Path '.\WixPackage\payload\Integrator\components' | Out-Null; Set-Content -Path '.\WixPackage\payload\Integrator\components\distribution.txt' -Value 'mode=wso2' -NoNewline }"
if errorlevel 1 (
    echo Failed to create distribution marker
    exit /b 1
)

REM INSTALLER_PROFILE (env): "full" (default) ships the editor + all runtimes; "editor-update"
REM produces the small editor-only update MSI (§D8) by skipping the Ballerina runtime — the
REM client seeds/resolves Ballerina from the per-user data folder, so an editor-only major
REM upgrade never strands it. The WiX payload glob (.\payload\Integrator\**) naturally excludes
REM whatever is not extracted here.
if not defined INSTALLER_PROFILE set "INSTALLER_PROFILE=full"
echo Installer profile: %INSTALLER_PROFILE%

REM Extract ballerina.zip (skipped for the editor-update profile)
if /i "%INSTALLER_PROFILE%"=="editor-update" goto :after_ballerina_extract
echo Extracting Ballerina to payload
REM Extract distributions directory (actual Ballerina runtime) to components\ballerina
REM and remove docs/examples to reduce installer size
powershell -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; $extractDir = 'C:\tmp_bal'; Remove-Item -Recurse -Force $extractDir -ErrorAction SilentlyContinue; New-Item -ItemType Directory -Force -Path $extractDir | Out-Null; [IO.Compression.ZipFile]::ExtractToDirectory('%~1', $extractDir); $unzippedFolder = (Get-ChildItem $extractDir -Directory | Select-Object -First 1).FullName; $ballerinaTarget = '.\WixPackage\payload\Integrator\components\ballerina'; New-Item -ItemType Directory -Force -Path $ballerinaTarget | Out-Null; $distDir = Join-Path $unzippedFolder 'distributions'; if (Test-Path $distDir) { $distFolder = (Get-ChildItem $distDir -Directory | Select-Object -First 1).FullName; if ($distFolder) { Copy-Item -Path \"$distFolder\*\" -Destination $ballerinaTarget -Recurse -Force } }; Remove-Item -Recurse -Force (Join-Path $ballerinaTarget 'docs') -ErrorAction SilentlyContinue; Remove-Item -Recurse -Force (Join-Path $ballerinaTarget 'examples') -ErrorAction SilentlyContinue; Remove-Item -Recurse -Force $extractDir }"
if errorlevel 1 (
    echo Ballerina extraction failed
    exit /b 1
)
:after_ballerina_extract

REM Add custom Ballerina update assets
echo Adding Ballerina update assets
powershell -nologo -noprofile -command "& { $ErrorActionPreference = 'Stop'; Add-Type -A 'System.IO.Compression.FileSystem'; $assetsDir = '%BALLERINA_ASSETS_DIR%'; $updateScript = '%~dp0WixPackage\balscript\wso2integratorupdate.bat'; $integratorTarget = '.\WixPackage\payload\Integrator'; $ballerinaTarget = Join-Path $integratorTarget 'components\ballerina'; $ballerinaBinTarget = Join-Path $ballerinaTarget 'bin'; $ballerinaUpdatesTarget = Join-Path $ballerinaTarget 'updates'; $integratorBinTarget = Join-Path $integratorTarget 'bin'; $updatesExtractDir = 'C:\tmp_bal_updates'; New-Item -ItemType Directory -Force -Path $integratorBinTarget, $ballerinaBinTarget, $ballerinaUpdatesTarget | Out-Null; Copy-Item -Force (Join-Path $assetsDir 'LICENSE') (Join-Path $ballerinaTarget 'LICENSE'); Copy-Item -Force (Join-Path $assetsDir 'update_tool_setup.ps1') (Join-Path $ballerinaBinTarget 'update_tool_setup.ps1'); Copy-Item -Force (Join-Path $assetsDir 'wso2integratorupdate_dist.ps1') (Join-Path $ballerinaBinTarget 'wso2integratorupdate_dist.ps1'); Copy-Item -Force $updateScript (Join-Path $integratorBinTarget 'wso2integratorupdate.bat'); Remove-Item -Recurse -Force $updatesExtractDir -ErrorAction SilentlyContinue; New-Item -ItemType Directory -Force -Path $updatesExtractDir | Out-Null; [IO.Compression.ZipFile]::ExtractToDirectory((Join-Path $assetsDir 'updates.zip'), $updatesExtractDir); $updatesRoot = Join-Path $updatesExtractDir 'updates'; if (Test-Path $updatesRoot) { Copy-Item -Path (Join-Path $updatesRoot '*') -Destination $ballerinaUpdatesTarget -Recurse -Force } else { Copy-Item -Path (Join-Path $updatesExtractDir '*') -Destination $ballerinaUpdatesTarget -Recurse -Force }; Remove-Item -Recurse -Force $updatesExtractDir }"
if errorlevel 1 (
    echo Ballerina update asset staging failed
    exit /b 1
)

REM editor-update (§D8 / W-B): the small update MSI is truly editor-only — skip ICP + JRE too
REM (in addition to Ballerina). The client seeds them to the data folder; ICP requires the MI
REM extension to read WSO2_INTEGRATOR_ICP_HOME before this build is published (go-live gate).
if /i "%INSTALLER_PROFILE%"=="editor-update" goto :after_runtimes

@REM REM Extract ICP.zip
powershell -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::ExtractToDirectory('%~4', '.\temp_icp'); $icpDir = (Get-ChildItem '.\temp_icp' -Directory | Select-Object -First 1).FullName; $icpTarget = '.\WixPackage\payload\Integrator\components\icp'; New-Item -ItemType Directory -Force -Path $icpTarget | Out-Null; Copy-Item -Path \"$icpDir\*\" -Destination $icpTarget -Recurse -Force; Remove-Item -Recurse -Force '.\temp_icp' }"
if errorlevel 1 (
    echo ICP extraction failed
    exit /b 1
)

REM Add custom ICP update assets
echo Adding ICP update assets
powershell -nologo -noprofile -command "& { $ErrorActionPreference = 'Stop'; Add-Type -A 'System.IO.Compression.FileSystem'; $assetsDir = '%ICP_ASSETS_DIR%'; $icpTarget = '.\WixPackage\payload\Integrator\components\icp'; $binTarget = Join-Path $icpTarget 'bin'; $updatesTarget = Join-Path $icpTarget 'updates'; $updatesExtractDir = 'C:\tmp_icp_updates'; New-Item -ItemType Directory -Force -Path $binTarget, $updatesTarget | Out-Null; Copy-Item -Force (Join-Path $assetsDir 'LICENSE') (Join-Path $icpTarget 'LICENSE'); Copy-Item -Force (Join-Path $assetsDir 'update_tool_setup.ps1') (Join-Path $binTarget 'update_tool_setup.ps1'); Remove-Item -Recurse -Force $updatesExtractDir -ErrorAction SilentlyContinue; New-Item -ItemType Directory -Force -Path $updatesExtractDir | Out-Null; [IO.Compression.ZipFile]::ExtractToDirectory((Join-Path $assetsDir 'updates.zip'), $updatesExtractDir); $updatesRoot = Join-Path $updatesExtractDir 'updates'; if (Test-Path $updatesRoot) { Copy-Item -Path (Join-Path $updatesRoot '*') -Destination $updatesTarget -Recurse -Force } else { Copy-Item -Path (Join-Path $updatesExtractDir '*') -Destination $updatesTarget -Recurse -Force }; Remove-Item -Recurse -Force $updatesExtractDir }"
if errorlevel 1 (
    echo ICP update asset staging failed
    exit /b 1
)

REM Extract JRE zip into shared dependencies directory
echo Extracting JRE to shared dependencies directory
powershell -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; $dependenciesTarget = '.\WixPackage\payload\Integrator\components\dependencies'; if (Test-Path $dependenciesTarget) { Remove-Item -Recurse -Force $dependenciesTarget }; New-Item -ItemType Directory -Force -Path $dependenciesTarget | Out-Null; [IO.Compression.ZipFile]::ExtractToDirectory('%~5', $dependenciesTarget); }"
if errorlevel 1 (
    echo JRE extraction failed
    exit /b 1
)

REM Modify icp.bat to use the JRE from shared dependencies directory (§D8): prefer
REM WSO2_INTEGRATOR_JRE_HOME (set by main.ts once ICP/JRE are seeded to the data
REM folder), else the JRE bundled next to ICP. The rewrite lives in a standalone
REM script because its embedded quotes/parens corrupt cmd.exe quote tracking inline.
echo Modifying icp.bat to use JRE from dependencies
powershell -nologo -noprofile -ExecutionPolicy Bypass -File "%~dp0scripts\patch-icp-jre.ps1"
if errorlevel 1 (
    echo ERROR: failed to patch icp.bat for env-aware JRE
    exit /b 1
)
:after_runtimes

REM Copy balscript/bal to ballerina bin directory and replace version placeholder
REM (skipped for editor-update: there is no bundled Ballerina in that payload)
if /i "%INSTALLER_PROFILE%"=="editor-update" goto :after_balbat
set "BAL_SRC=%~dp0WixPackage\balscript\bal.bat"
set "BAL_TARGET=.\WixPackage\payload\Integrator\components\ballerina\bin\bal.bat"
if exist "%BAL_SRC%" (
    if not exist ".\WixPackage\payload\Integrator\components\ballerina\bin" mkdir ".\WixPackage\payload\Integrator\components\ballerina\bin"
    powershell -nologo -noprofile -command "& { (Get-Content '%BAL_SRC%') -replace '@BALLERINA_VERSION@', '%~2' | Set-Content '%BAL_TARGET%' }"
    echo Copied bal.bat to ballerina bin directory with version %~2
) else (
    echo bal.bat not found at %BAL_SRC%
)
:after_balbat



REM Compute WiX ProductVersion. Windows Installer only compares the first THREE fields, so the
REM 4-part integrator.version (a.b.c.d, e.g. 5.0.0.1) would not upgrade on a 4th-field bump.
REM Fold the revision into the build field: a.b.(c*1000+d)  ->  5.0.0.1 becomes 5.0.1 (§D8).
REM Constraint: c<=64 and d<=999 (build field max 65535). Pre-release suffixes (-m1, -09181) are
REM STRIPPED, so every pre-release of one core carries the SAME ProductVersion — that is only
REM sound because Package.wxs sets MajorUpgrade AllowSameVersionUpgrades="yes" (same-version
REM installs replace the registered product instead of stacking a second one). Keep the two in
REM sync; do not fold the suffix in here instead (it would outrank the GA's a.b.c and block the
REM final-release upgrade).
REM Clear first so a failed computation can't inherit a stale value from the environment.
set "WIX_VERSION="
for /f "delims=" %%v in ('powershell -nologo -noprofile -command "$p=(('%~6' -split '-')[0] -split '\.'); while($p.Count -lt 4){$p+='0'}; $a=[int]$p[0]; $b=[int]$p[1]; $c=[int]$p[2]; $d=[int]$p[3]; if($c -gt 64 -or $d -gt 999){[Console]::Error.WriteLine('ProductVersion fold out of range (need c<=64,d<=999): %~6'); exit 1}; '{0}.{1}.{2}' -f $a,$b,($c*1000+$d)"') do set "WIX_VERSION=%%v"
if not defined WIX_VERSION (
    echo ERROR: failed to compute WiX ProductVersion from %~6
    exit /b 1
)
echo WiX ProductVersion: %WIX_VERSION%


REM Update version in Package.wxs
powershell -Command "(Get-Content '.\WixPackage\Package.wxs') -replace '@VERSION@', '%WIX_VERSION%' | Set-Content '.\WixPackage\Package.wxs'"

REM Map build directory to a short drive letter to keep file paths under 260 chars.
REM wixnative.exe lacks a longPathAware manifest, so it crashes on paths > 260 chars.
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

REM Find an unused drive letter (W, X, Y, Z) and map it via subst.
set "BUILD_DRIVE="
for %%L in (W X Y Z) do (
    if not defined BUILD_DRIVE if not exist %%L:\ (
        subst %%L: "%SCRIPT_DIR%" >nul 2>&1
        if not errorlevel 1 set "BUILD_DRIVE=%%L"
    )
)
if not defined BUILD_DRIVE (
    echo ERROR: No available drive letter found ^(W-Z all in use or subst failed^)
    powershell -Command "(Get-Content -Raw '.\WixPackage\Package.wxs').Replace('%WIX_VERSION%', '@VERSION@') | Set-Content '.\WixPackage\Package.wxs'"
    if exist ".\WixPackage\payload" rmdir /s /q ".\WixPackage\payload"
    exit /b 1
)
pushd %BUILD_DRIVE%:\
if errorlevel 1 (
    echo ERROR: pushd into %BUILD_DRIVE%:\ failed
    subst %BUILD_DRIVE%: /D >nul 2>&1
    powershell -Command "(Get-Content -Raw '.\WixPackage\Package.wxs').Replace('%WIX_VERSION%', '@VERSION@') | Set-Content '.\WixPackage\Package.wxs'"
    if exist ".\WixPackage\payload" rmdir /s /q ".\WixPackage\payload"
    exit /b 1
)

dotnet build .\CustomAction1\CustomAction1.csproj -c Release
if errorlevel 1 (
    echo CustomAction1 build failed
    popd
    subst %BUILD_DRIVE%: /D
    powershell -Command "(Get-Content -Raw '.\WixPackage\Package.wxs').Replace('%WIX_VERSION%', '@VERSION@') | Set-Content '.\WixPackage\Package.wxs'"
    exit /b 1
)
dotnet build .\WixPackage\WixPackage.wixproj -p:Platform=x64 -p:Configuration=Release -maxcpucount:1 -v:detailed
if errorlevel 1 (
    echo WixPackage build failed
    popd
    subst %BUILD_DRIVE%: /D
    powershell -Command "(Get-Content -Raw '.\WixPackage\Package.wxs').Replace('%WIX_VERSION%', '@VERSION@') | Set-Content '.\WixPackage\Package.wxs'"
    exit /b 1
)

popd
subst %BUILD_DRIVE%: /D

REM Rename MSI output to include version. The editor-update profile gets a "-update" suffix so
REM the small editor-only MSI (published to the update manifest) is distinct from the full
REM first-install MSI. Both share the same UpgradeCode, so -update cleanly upgrades a full install.
set "MSI_SUFFIX="
if /i "%INSTALLER_PROFILE%"=="editor-update" set "MSI_SUFFIX=-update"
set "MSI_ORIG=WixPackage\bin\x64\Release\en-US\WSO2-Integrator.msi"
set "MSI_NEW=WixPackage\bin\x64\Release\en-US\wso2-integrator-%~6%MSI_SUFFIX%.msi"
if exist "%MSI_ORIG%" (
    ren "%MSI_ORIG%" "wso2-integrator-%~6%MSI_SUFFIX%.msi"
    echo Renamed MSI to %MSI_NEW%
) else (
    echo MSI file not found: %MSI_ORIG%
)

REM Revert version placeholder in Package.wxs
powershell -Command "(Get-Content -Raw '.\WixPackage\Package.wxs').Replace('%WIX_VERSION%', '@VERSION@') | Set-Content '.\WixPackage\Package.wxs'"
REM Remove payload and resources directories after build
if exist ".\WixPackage\payload" rmdir /s /q ".\WixPackage\payload"
endlocal

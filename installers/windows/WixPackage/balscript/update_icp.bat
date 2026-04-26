@echo off
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"

if /I "%~1"=="-h" goto help
if /I "%~1"=="--help" goto help

set "ICP_UPDATE_TOOL="
for /f "delims=" %%F in ('dir /b /a-d /on "%SCRIPT_DIR%wso2update_*.exe" 2^>nul') do (
    set "ICP_UPDATE_TOOL=%SCRIPT_DIR%%%F"
    goto found_tool
)

:found_tool
if not defined ICP_UPDATE_TOOL (
    if not exist "%SCRIPT_DIR%update_tool_setup.ps1" (
        echo Error: update_tool_setup.ps1 not found in "%SCRIPT_DIR%"
        exit /b 1
    )

    pushd "%SCRIPT_DIR%"
    powershell -nologo -noprofile -ExecutionPolicy Bypass -File ".\update_tool_setup.ps1"
    if errorlevel 1 (
        popd
        exit /b 1
    )
    popd

    for /f "delims=" %%F in ('dir /b /a-d /on "%SCRIPT_DIR%wso2update_*.exe" 2^>nul') do (
        set "ICP_UPDATE_TOOL=%SCRIPT_DIR%%%F"
        goto found_tool_after_setup
    )
)

:found_tool_after_setup
if not defined ICP_UPDATE_TOOL (
    echo Error: ICP update executable not found in "%SCRIPT_DIR%"
    exit /b 1
)

call "%ICP_UPDATE_TOOL%" %*
exit /b %errorlevel%

:help
echo Update ICP connects to the WSO2 Update service, finds product updates that are
echo relevant to the installed WSO2 Integration Control Plane, and applies them.
echo(
echo To learn more about WSO2 Update, visit https://wso2.com/updates
echo(
echo Usage:
echo   update icp [flags]
echo   update icp [command]
echo(
echo Examples:
echo   update icp version
echo   update icp help check
echo   update icp
echo   update icp --username user@wso2.com --password my_password
echo   update icp --level 3.0.0.10
echo   update icp --dry-run
echo(
echo Available Commands:
echo   apply-hotfix   Apply an available hotfix.
echo   apply-update   Apply a created update zip file to the product.
echo   check          Check available new levels for the product.
echo   completion     Generate shell autocompletion scripts.
echo   create-docker  Create a Docker image of the product.
echo   create-update  Create an update zip file for the product.
echo   current-state  Show current details of the product.
echo   help           Help about any command.
echo   revert-hotfix  Revert the most recently applied hotfix.
echo   version        Print the update tool version information.
echo(
echo Flags:
echo   -b, --backup string     Specify updates backup directory
echo   -c, --channel string    Channel updates should be downloaded from ^(default "full"^)
echo       --continue          Merge resolved conflicts
echo       --dry-run           Simulate the update
echo   -h, --help              help for update icp
echo   -l, --level string      Level in which the product should be updated to
echo       --no-backup         Skip product backup
echo   -p, --password string   Specify your WSO2 account password
echo       --revert            Revert to the previous update level
echo       --template string   Specify the template output
echo   -u, --username string   Specify your WSO2 account email
echo   -v, --verbose           Enable verbose mode
exit /b 0

@echo off
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "ICP_UPDATE_SCRIPT=%SCRIPT_DIR%..\..\icp\bin\update_icp.bat"

set "COMMAND=%~1"
if "%COMMAND%"=="" goto usage
shift

set "FIRST_ARG=%~1"
shift

set "REMAINING_ARGS="
:collect_args
if "%~1"=="" goto args_collected
if defined REMAINING_ARGS (
    set "REMAINING_ARGS=!REMAINING_ARGS! %1"
) else (
    set "REMAINING_ARGS=%1"
)
shift
goto collect_args

:args_collected

if /I "%COMMAND%"=="ballerina" goto ballerina
if /I "%COMMAND%"=="icp" goto icp

:usage
echo Usage: update ^<ballerina^|icp^> [args...]
exit /b 1

:ballerina
if /I "%FIRST_ARG%"=="-h" goto ballerina_help
if /I "%FIRST_ARG%"=="--help" goto ballerina_help
if defined FIRST_ARG (
    if defined REMAINING_ARGS (
        set "FORWARD_ARGS=%FIRST_ARG% %REMAINING_ARGS%"
    ) else (
        set "FORWARD_ARGS=%FIRST_ARG%"
    )
) else (
    set "FORWARD_ARGS="
)
call "%SCRIPT_DIR%bal.bat" update %FORWARD_ARGS%
exit /b %errorlevel%

:ballerina_help
echo Update Ballerina connects to the WSO2 Update service, finds product updates that are
echo relevant to the installed Ballerina, and applies them.
echo(
echo To learn more about WSO2 Update, visit https://wso2.com/updates
echo(
echo Usage:
echo   update ballerina [flags]
echo   update ballerina [command]
echo(
echo Examples:
echo   update ballerina version
echo   update ballerina help check
echo   update ballerina
echo   update ballerina --username user@wso2.com --password my_password
echo   update ballerina --level 3.0.0.10
echo   update ballerina --dry-run
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
echo   -h, --help              help for update ballerina
echo   -l, --level string      Level in which the product should be updated to
echo       --no-backup         Skip product backup
echo   -p, --password string   Specify your WSO2 account password
echo       --revert            Revert to the previous update level
echo       --template string   Specify the template output
echo   -u, --username string   Specify your WSO2 account email
echo   -v, --verbose           Enable verbose mode
exit /b 0

:icp
if defined FIRST_ARG (
    if defined REMAINING_ARGS (
        set "FORWARD_ARGS=%FIRST_ARG% %REMAINING_ARGS%"
    ) else (
        set "FORWARD_ARGS=%FIRST_ARG%"
    )
) else (
    set "FORWARD_ARGS="
)
call "%ICP_UPDATE_SCRIPT%" %FORWARD_ARGS%
exit /b %errorlevel%

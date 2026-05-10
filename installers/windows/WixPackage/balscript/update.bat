@echo off
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "MI_CACHE_DIR=%USERPROFILE%\.wso2-mi\micro-integrator"
set "SI_CACHE_DIR=%USERPROFILE%\.wso2-si\streaming-integrator"
set "PROFILE_STATE_FILE=%USERPROFILE%\.wso2-integrator\selected-profile"

set "APP_ROOT=%SCRIPT_DIR%.."
if not exist "%APP_ROOT%\components\ballerina\bin\wso2integratorupdate.ps1" (
    set "APP_ROOT=%SCRIPT_DIR%..\.."
)
if not exist "%APP_ROOT%\components\ballerina\bin\wso2integratorupdate.ps1" (
    set "APP_ROOT=%SCRIPT_DIR%..\..\.."
)

set "BALLERINA_UPDATE_SCRIPT=%APP_ROOT%\components\ballerina\bin\wso2integratorupdate.ps1"
set "ICP_BIN_DIR=%APP_ROOT%\components\icp\bin"

if /I "%~1"=="-h" goto top_help
if /I "%~1"=="--help" goto top_help
if /I "%~1"=="help" goto top_help

if "%~1"=="" (
    call :resolve_profile_command
    set "COMMAND=!RESOLVED_COMMAND!"
) else (
    if /I "%~1"=="ballerina" (
        set "COMMAND=ballerina"
        shift
    ) else if /I "%~1"=="icp" (
        set "COMMAND=icp"
        shift
    ) else if /I "%~1"=="mi" (
        set "COMMAND=mi"
        shift
    ) else if /I "%~1"=="si" (
        set "COMMAND=si"
        shift
    ) else (
        call :resolve_profile_command
        set "COMMAND=!RESOLVED_COMMAND!"
    )
)

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
if /I "%COMMAND%"=="mi" goto mi
if /I "%COMMAND%"=="si" goto si

:usage
echo Usage: update [flags]
echo Usage: update ^<ballerina^|icp^|mi^|si^> [args...]
exit /b 1

:top_help
echo Usage: update [flags]
echo Usage: update ^<ballerina^|icp^|mi^|si^> [args...]
echo(
echo The default command is selected from the active Integration Profile.
exit /b 0

:resolve_profile_command
set "RESOLVED_COMMAND=ballerina"
if exist "%PROFILE_STATE_FILE%" (
    set "PROFILE_VALUE="
    set /p PROFILE_VALUE=<"%PROFILE_STATE_FILE%"
    if /I "%PROFILE_VALUE%"=="WSO2 Integrator: MI" set "RESOLVED_COMMAND=mi"
    if /I "%PROFILE_VALUE%"=="WSO2 Integrator: SI" set "RESOLVED_COMMAND=si"
)
goto :eof

:ballerina
if /I "%FIRST_ARG%"=="-h" goto ballerina_help
if /I "%FIRST_ARG%"=="--help" goto ballerina_help
if /I "%FIRST_ARG%"=="help" goto ballerina_help
if defined FIRST_ARG (
    if defined REMAINING_ARGS (
        set "FORWARD_ARGS=%FIRST_ARG% %REMAINING_ARGS%"
    ) else (
        set "FORWARD_ARGS=%FIRST_ARG%"
    )
) else (
    set "FORWARD_ARGS="
)
call powershell -nologo -noprofile -ExecutionPolicy Bypass -File "%BALLERINA_UPDATE_SCRIPT%" %FORWARD_ARGS%
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
if /I "%FIRST_ARG%"=="-h" goto icp_help
if /I "%FIRST_ARG%"=="--help" goto icp_help
if /I "%FIRST_ARG%"=="help" goto icp_help

if defined FIRST_ARG (
    if defined REMAINING_ARGS (
        set "FORWARD_ARGS=%FIRST_ARG% %REMAINING_ARGS%"
    ) else (
        set "FORWARD_ARGS=%FIRST_ARG%"
    )
) else (
    set "FORWARD_ARGS="
)

set "ICP_UPDATE_TOOL="
for /f "delims=" %%F in ('dir /b /a-d /on "%ICP_BIN_DIR%\wso2update_*.exe" 2^>nul') do (
    set "ICP_UPDATE_TOOL=%ICP_BIN_DIR%\%%F"
    goto icp_found
)

:icp_found
if not defined ICP_UPDATE_TOOL (
    if not exist "%ICP_BIN_DIR%\update_tool_setup.ps1" (
        echo Error: update_tool_setup.ps1 not found in "%ICP_BIN_DIR%"
        exit /b 1
    )

    pushd "%ICP_BIN_DIR%"
    powershell -nologo -noprofile -ExecutionPolicy Bypass -File ".\update_tool_setup.ps1"
    if errorlevel 1 (
        popd
        exit /b 1
    )
    popd

    for /f "delims=" %%F in ('dir /b /a-d /on "%ICP_BIN_DIR%\wso2update_*.exe" 2^>nul') do (
        set "ICP_UPDATE_TOOL=%ICP_BIN_DIR%\%%F"
        goto icp_found_after_setup
    )
)

:icp_found_after_setup
if not defined ICP_UPDATE_TOOL (
    echo Error: ICP update executable not found in "%ICP_BIN_DIR%"
    exit /b 1
)

call "%ICP_UPDATE_TOOL%" %FORWARD_ARGS%
exit /b %errorlevel%

:icp_help
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
exit /b %errorlevel%

:mi
if /I "%FIRST_ARG%"=="-h" goto mi_help
if /I "%FIRST_ARG%"=="--help" goto mi_help
if /I "%FIRST_ARG%"=="help" goto mi_help

set "MI_UPDATE_TOOL="
for /f "delims=" %%F in ('dir /s /b /a-d /on "%MI_CACHE_DIR%\wso2update_windows.exe" 2^>nul') do (
    set "MI_UPDATE_TOOL=%%F"
    goto mi_found
)

:mi_found
if not defined MI_UPDATE_TOOL (
    echo Error: MI update executable not found for Windows. Please open/create a MI project. MI not in your machine.
    exit /b 1
)

if defined FIRST_ARG (
    if defined REMAINING_ARGS (
        set "FORWARD_ARGS=%FIRST_ARG% %REMAINING_ARGS%"
    ) else (
        set "FORWARD_ARGS=%FIRST_ARG%"
    )
) else (
    set "FORWARD_ARGS="
)
call "%MI_UPDATE_TOOL%" %FORWARD_ARGS%
exit /b %errorlevel%

:mi_help
echo Update MI connects to the WSO2 Update service, finds product updates that are
echo relevant to the installed MI, and applies them.
echo(
echo To learn more about WSO2 Update, visit https://wso2.com/updates
echo(
echo Usage:
echo   update mi [flags]
echo   update mi [command]
echo(
echo Examples:
echo   update mi version
echo   update mi help check
echo   update mi
echo   update mi --username user@wso2.com --password my_password
echo   update mi --level 3.0.0.10
echo   update mi --dry-run
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
echo   -h, --help              help for update mi
echo   -l, --level string      Level in which the product should be updated to
echo       --no-backup         Skip product backup
echo   -p, --password string   Specify your WSO2 account password
echo       --revert            Revert to the previous update level
echo       --template string   Specify the template output
echo   -u, --username string   Specify your WSO2 account email
echo   -v, --verbose           Enable verbose mode
exit /b 0

:si
if /I "%FIRST_ARG%"=="-h" goto si_help
if /I "%FIRST_ARG%"=="--help" goto si_help
if /I "%FIRST_ARG%"=="help" goto si_help

set "SI_UPDATE_TOOL="
for /f "delims=" %%F in ('dir /s /b /a-d /on "%SI_CACHE_DIR%\wso2update_windows.exe" 2^>nul') do (
    set "SI_UPDATE_TOOL=%%F"
    goto si_found
)

:si_found
if not defined SI_UPDATE_TOOL (
    echo Error: SI update executable not found for Windows. Please open/create a SI project. SI not in your machine.
    exit /b 1
)

if defined FIRST_ARG (
    if defined REMAINING_ARGS (
        set "FORWARD_ARGS=%FIRST_ARG% %REMAINING_ARGS%"
    ) else (
        set "FORWARD_ARGS=%FIRST_ARG%"
    )
) else (
    set "FORWARD_ARGS="
)
call "%SI_UPDATE_TOOL%" %FORWARD_ARGS%
exit /b %errorlevel%

:si_help
echo Update SI connects to the WSO2 Update service, finds product updates that are
echo relevant to the installed SI, and applies them.
echo(
echo To learn more about WSO2 Update, visit https://wso2.com/updates
echo(
echo Usage:
echo   update si [flags]
echo   update si [command]
echo(
echo Examples:
echo   update si version
echo   update si help check
echo   update si
echo   update si --username user@wso2.com --password my_password
echo   update si --level 3.0.0.10
echo   update si --dry-run
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
echo   -h, --help              help for update si
echo   -l, --level string      Level in which the product should be updated to
echo       --no-backup         Skip product backup
echo   -p, --password string   Specify your WSO2 account password
echo       --revert            Revert to the previous update level
echo       --template string   Specify the template output
echo   -u, --username string   Specify your WSO2 account email
echo   -v, --verbose           Enable verbose mode
exit /b 0

@echo off
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "MI_CACHE_DIR=%USERPROFILE%\.wso2-mi\micro-integrator"
set "SI_CACHE_DIR=%USERPROFILE%\.wso2-si\streaming-integrator"
set "PROFILE_STATE_FILE=%USERPROFILE%\.wso2-integrator\selected-profile"

set "APP_ROOT=%SCRIPT_DIR%.."
if not exist "%APP_ROOT%\components\ballerina\bin\wso2integratorupdate_dist.ps1" (
    set "APP_ROOT=%SCRIPT_DIR%..\.."
)
if not exist "%APP_ROOT%\components\ballerina\bin\wso2integratorupdate_dist.ps1" (
    set "APP_ROOT=%SCRIPT_DIR%..\..\.."
)

set "BALLERINA_UPDATE_SCRIPT=%APP_ROOT%\components\ballerina\bin\wso2integratorupdate_dist.ps1"
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
echo Usage: wso2integratorupdate [command] [flags]
echo Usage: wso2integratorupdate ^<ballerina^|icp^|mi^|si^> [command] [flags]
exit /b 1

:top_help
echo Usage: wso2integratorupdate [command] [flags]
echo Usage: wso2integratorupdate ^<ballerina^|icp^|mi^|si^> [command] [flags]
echo(
echo   ballerina   Run the Ballerina update flow.
echo   icp         Run the ICP update flow.
echo   mi          Run the MI update flow.
echo   si          Run the SI update flow.
echo(
echo The default command is selected from the active Integration Profile.
echo(
echo Examples:
echo   wso2integratorupdate check
echo   wso2integratorupdate version
echo   wso2integratorupdate help check
echo   wso2integratorupdate current-state
echo   wso2integratorupdate --revert
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
echo   -h, --help              help for wso2integratorupdate
echo   -l, --level string      Level in which the product should be updated to
echo       --no-backup         Skip product backup
echo   -p, --password string   Specify your WSO2 account password
echo       --revert            Revert to the previous update level
echo       --template string   Specify the template output
echo   -u, --username string   Specify your WSO2 account email
echo   -v, --verbose           Enable verbose mode
exit /b 0

:is_valid_update_invocation
set "VALID_UPDATE_INVOCATION="
if "%FIRST_ARG%"=="" (
    set "VALID_UPDATE_INVOCATION=1"
    goto :eof
)

if /I "%FIRST_ARG%"=="-h" set "VALID_UPDATE_INVOCATION=1"
if /I "%FIRST_ARG%"=="--help" set "VALID_UPDATE_INVOCATION=1"
if /I "%FIRST_ARG%"=="help" set "VALID_UPDATE_INVOCATION=1"
if /I "%FIRST_ARG%"=="version" set "VALID_UPDATE_INVOCATION=1"
if /I "%FIRST_ARG%"=="current-state" set "VALID_UPDATE_INVOCATION=1"
if /I "%FIRST_ARG%"=="check" set "VALID_UPDATE_INVOCATION=1"
if /I "%FIRST_ARG%"=="completion" set "VALID_UPDATE_INVOCATION=1"
if /I "%FIRST_ARG%"=="apply-hotfix" set "VALID_UPDATE_INVOCATION=1"
if /I "%FIRST_ARG%"=="apply-update" set "VALID_UPDATE_INVOCATION=1"
if /I "%FIRST_ARG%"=="create-docker" set "VALID_UPDATE_INVOCATION=1"
if /I "%FIRST_ARG%"=="create-update" set "VALID_UPDATE_INVOCATION=1"
if /I "%FIRST_ARG%"=="revert-hotfix" set "VALID_UPDATE_INVOCATION=1"
if /I "%FIRST_ARG%"=="--username" set "VALID_UPDATE_INVOCATION=1"
if /I "%FIRST_ARG%"=="-u" set "VALID_UPDATE_INVOCATION=1"
if /I "%FIRST_ARG%"=="--password" set "VALID_UPDATE_INVOCATION=1"
if /I "%FIRST_ARG%"=="-p" set "VALID_UPDATE_INVOCATION=1"
if /I "%FIRST_ARG%"=="--level" set "VALID_UPDATE_INVOCATION=1"
if /I "%FIRST_ARG%"=="-l" set "VALID_UPDATE_INVOCATION=1"
if /I "%FIRST_ARG%"=="--backup" set "VALID_UPDATE_INVOCATION=1"
if /I "%FIRST_ARG%"=="-b" set "VALID_UPDATE_INVOCATION=1"
if /I "%FIRST_ARG%"=="--channel" set "VALID_UPDATE_INVOCATION=1"
if /I "%FIRST_ARG%"=="-c" set "VALID_UPDATE_INVOCATION=1"
if /I "%FIRST_ARG%"=="--continue" set "VALID_UPDATE_INVOCATION=1"
if /I "%FIRST_ARG%"=="--dry-run" set "VALID_UPDATE_INVOCATION=1"
if /I "%FIRST_ARG%"=="--no-backup" set "VALID_UPDATE_INVOCATION=1"
if /I "%FIRST_ARG%"=="--revert" set "VALID_UPDATE_INVOCATION=1"
if /I "%FIRST_ARG%"=="--template" set "VALID_UPDATE_INVOCATION=1"
if /I "%FIRST_ARG%"=="--verbose" set "VALID_UPDATE_INVOCATION=1"
goto :eof

:guard_if_running
set "GUARD_PRODUCT=%~1"
call :is_safe_subcommand
if defined SAFE_SUBCOMMAND exit /b 0
call :is_integrator_running
if not defined INTEGRATOR_RUNNING exit /b 0
call :show_close_banner "%GUARD_PRODUCT%"
exit /b 1

:is_safe_subcommand
set "SAFE_SUBCOMMAND="
if /I "%FIRST_ARG%"=="-h" set "SAFE_SUBCOMMAND=1"
if /I "%FIRST_ARG%"=="--help" set "SAFE_SUBCOMMAND=1"
if /I "%FIRST_ARG%"=="help" set "SAFE_SUBCOMMAND=1"
if /I "%FIRST_ARG%"=="version" set "SAFE_SUBCOMMAND=1"
if /I "%FIRST_ARG%"=="current-state" set "SAFE_SUBCOMMAND=1"
if /I "%FIRST_ARG%"=="check" set "SAFE_SUBCOMMAND=1"
if /I "%FIRST_ARG%"=="completion" set "SAFE_SUBCOMMAND=1"
goto :eof

:is_integrator_running
set "INTEGRATOR_RUNNING="
tasklist /FI "IMAGENAME eq WSO2 Integrator.exe" /NH 2>nul | find /I "WSO2 Integrator.exe" >nul
if not errorlevel 1 set "INTEGRATOR_RUNNING=1"
goto :eof

:show_close_banner
set "BANNER_PRODUCT=%~1"
echo.
echo WSO2 Integrator is running.
echo Please close the app and run this in a terminal to update:
if defined REMAINING_ARGS (
    echo   wso2integratorupdate %BANNER_PRODUCT% %FIRST_ARG% %REMAINING_ARGS%
) else if defined FIRST_ARG (
    echo   wso2integratorupdate %BANNER_PRODUCT% %FIRST_ARG%
) else (
    echo   wso2integratorupdate %BANNER_PRODUCT%
)
echo.
exit /b 1

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
call :is_valid_update_invocation
if not defined VALID_UPDATE_INVOCATION goto invalid_update_invocation
call :guard_if_running ballerina
if errorlevel 1 exit /b 1
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
echo   wso2integratorupdate ballerina [flags]
echo   wso2integratorupdate ballerina [command]
echo(
echo Examples:
echo   wso2integratorupdate ballerina version
echo   wso2integratorupdate ballerina help check
echo   wso2integratorupdate ballerina
echo   wso2integratorupdate ballerina --username user@wso2.com --password my_password
echo   wso2integratorupdate ballerina --level 3.0.0.10
echo   wso2integratorupdate ballerina --dry-run
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
echo   -h, --help              help for wso2integratorupdate ballerina
echo   -l, --level string      Level in which the product should be updated to
echo       --no-backup         Skip product backup
echo   -p, --password string   Specify your WSO2 account password
echo       --revert            Revert to the previous update level
echo       --template string   Specify the template output
echo   -u, --username string   Specify your WSO2 account email
echo   -v, --verbose           Enable verbose mode
exit /b 0

:invalid_update_invocation
if defined FIRST_ARG (
    if "!FIRST_ARG:~0,1!"=="-" (
        echo Unknown option: %FIRST_ARG%
    ) else (
        echo Unknown command: %FIRST_ARG%
    )
) else (
    echo Unknown command.
)
echo(
echo Usage:
echo   wso2integratorupdate ballerina [flags]
echo   wso2integratorupdate ballerina [command]
exit /b 1

:icp
if /I "%FIRST_ARG%"=="-h" goto icp_help
if /I "%FIRST_ARG%"=="--help" goto icp_help
if /I "%FIRST_ARG%"=="help" goto icp_help
call :is_valid_update_invocation
if not defined VALID_UPDATE_INVOCATION goto invalid_update_invocation
call :guard_if_running icp
if errorlevel 1 exit /b 1

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
echo   wso2integratorupdate icp [flags]
echo   wso2integratorupdate icp [command]
echo(
echo Examples:
echo   wso2integratorupdate icp version
echo   wso2integratorupdate icp help check
echo   wso2integratorupdate icp
echo   wso2integratorupdate icp --username user@wso2.com --password my_password
echo   wso2integratorupdate icp --level 3.0.0.10
echo   wso2integratorupdate icp --dry-run
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
echo   -h, --help              help for wso2integratorupdate icp
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
call :is_valid_update_invocation
if not defined VALID_UPDATE_INVOCATION goto invalid_update_invocation

set "MI_UPDATE_TOOL="
for /f "delims=" %%F in ('dir /s /b /a-d /on "%MI_CACHE_DIR%\wso2update_windows.exe" 2^>nul') do (
    set "MI_UPDATE_TOOL=%%F"
    goto mi_found
)

:mi_found
if not defined MI_UPDATE_TOOL (
    set "MI_SETUP_SCRIPT="
    for /f "delims=" %%F in ('dir /s /b /a-d /on "%MI_CACHE_DIR%\bin\update_tool_setup.ps1" 2^>nul') do (
        set "MI_SETUP_SCRIPT=%%F"
        goto mi_setup_found
    )
)

:mi_setup_found
if not defined MI_SETUP_SCRIPT (
    echo Error: update_tool_setup.ps1 not found for MI. Please open/create a MI project. MI not in your machine.
    exit /b 1
)

set "MI_BIN_DIR=%MI_SETUP_SCRIPT%\.."
for %%I in ("%MI_BIN_DIR%") do set "MI_BIN_DIR=%%~fI"

if not defined MI_UPDATE_TOOL (
    pushd "%MI_BIN_DIR%"
    powershell -nologo -noprofile -ExecutionPolicy Bypass -File ".\update_tool_setup.ps1"
    if errorlevel 1 (
        popd
        exit /b 1
    )
    popd

    for /f "delims=" %%F in ('dir /b /a-d /on "%MI_BIN_DIR%\wso2update_*.exe" 2^>nul') do (
        set "MI_UPDATE_TOOL=%MI_BIN_DIR%\%%F"
        goto mi_found_after_setup
    )
)

:mi_found_after_setup
if not defined MI_UPDATE_TOOL (
    echo Error: MI update executable not found in "%MI_BIN_DIR%"
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
echo   wso2integratorupdate mi [flags]
echo   wso2integratorupdate mi [command]
echo(
echo Examples:
echo   wso2integratorupdate mi version
echo   wso2integratorupdate mi help check
echo   wso2integratorupdate mi
echo   wso2integratorupdate mi --username user@wso2.com --password my_password
echo   wso2integratorupdate mi --level 3.0.0.10
echo   wso2integratorupdate mi --dry-run
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
echo   -h, --help              help for wso2integratorupdate mi
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
call :is_valid_update_invocation
if not defined VALID_UPDATE_INVOCATION goto invalid_update_invocation

set "SI_UPDATE_TOOL="
for /f "delims=" %%F in ('dir /s /b /a-d /on "%SI_CACHE_DIR%\wso2update_windows.exe" 2^>nul') do (
    set "SI_UPDATE_TOOL=%%F"
    goto si_found
)

:si_found
if not defined SI_UPDATE_TOOL (
    set "SI_SETUP_SCRIPT="
    for /f "delims=" %%F in ('dir /s /b /a-d /on "%SI_CACHE_DIR%\bin\update_tool_setup.ps1" 2^>nul') do (
        set "SI_SETUP_SCRIPT=%%F"
        goto si_setup_found
    )
)

:si_setup_found
if not defined SI_SETUP_SCRIPT (
    echo Error: update_tool_setup.ps1 not found for SI. Please open/create a SI project. SI not in your machine.
    exit /b 1
)

set "SI_BIN_DIR=%SI_SETUP_SCRIPT%\.."
for %%I in ("%SI_BIN_DIR%") do set "SI_BIN_DIR=%%~fI"

if not defined SI_UPDATE_TOOL (
    pushd "%SI_BIN_DIR%"
    powershell -nologo -noprofile -ExecutionPolicy Bypass -File ".\update_tool_setup.ps1"
    if errorlevel 1 (
        popd
        exit /b 1
    )
    popd

    for /f "delims=" %%F in ('dir /b /a-d /on "%SI_BIN_DIR%\wso2update_*.exe" 2^>nul') do (
        set "SI_UPDATE_TOOL=%SI_BIN_DIR%\%%F"
        goto si_found_after_setup
    )
)

:si_found_after_setup
if not defined SI_UPDATE_TOOL (
    echo Error: SI update executable not found in "%SI_BIN_DIR%"
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
echo   wso2integratorupdate si [flags]
echo   wso2integratorupdate si [command]
echo(
echo Examples:
echo   wso2integratorupdate si version
echo   wso2integratorupdate si help check
echo   wso2integratorupdate si
echo   wso2integratorupdate si --username user@wso2.com --password my_password
echo   wso2integratorupdate si --level 3.0.0.10
echo   wso2integratorupdate si --dry-run
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
echo   -h, --help              help for wso2integratorupdate si
echo   -l, --level string      Level in which the product should be updated to
echo       --no-backup         Skip product backup
echo   -p, --password string   Specify your WSO2 account password
echo       --revert            Revert to the previous update level
echo       --template string   Specify the template output
echo   -u, --username string   Specify your WSO2 account email
echo   -v, --verbose           Enable verbose mode
exit /b 0

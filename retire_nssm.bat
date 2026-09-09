@echo off
:: Retire the old NSSM-based WPD watcher service.
:: Run as Administrator after the new right-click converter is deployed.
::
:: What this does:
::   1. Stops the NSSM service (wpdconverter)
::   2. Removes the NSSM service registration
::   3. Archives the old wpdconverter/ folder
::   4. Archives the network inbox/outbox folders (if reachable)

setlocal enabledelayedexpansion
net session >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: This script must be run as Administrator.
    pause
    exit /b 1
)

set "NSSM_EXE=%~dp0nssm-2.24-101-g897c7ad\win64\nssm.exe"
set "SERVICE_NAME=wpdconverter"
set "OLD_DIR=%~dp0wpdconverter"
set "NETWORK_INBOX=\\Win-em2un8j7eiv\i\WPD_INBOX"
set "NETWORK_OUTBOX=\\Win-em2un8j7eiv\i\WPD_FORMATTED"

echo ============================================================
echo   Retiring NSSM WPD Watcher
echo ============================================================
echo.

:: ---- Step 1: Stop the service ----
echo [1/4] Stopping service "%SERVICE_NAME%"...
sc query %SERVICE_NAME% >nul 2>&1
if %ERRORLEVEL% equ 0 (
    "%NSSM_EXE%" stop %SERVICE_NAME% >nul 2>&1
    timeout /t 3 /nobreak >nul
    sc query %SERVICE_NAME% | findstr /i "STOPPED" >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        echo       Service stopped.
    ) else (
        echo       WARNING: Service may still be running. Forcing stop...
        net stop %SERVICE_NAME% >nul 2>&1
        taskkill /f /im pythonw.exe >nul 2>&1
        echo       Forced stop attempted.
    )
) else (
    echo       Service not found - may already be removed.
)
echo.

:: ---- Step 2: Remove the service ----
echo [2/4] Removing NSSM service registration...
sc query %SERVICE_NAME% >nul 2>&1
if %ERRORLEVEL% equ 0 (
    "%NSSM_EXE%" remove %SERVICE_NAME% confirm >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        echo       Service removed.
    ) else (
        echo       WARNING: Could not remove service. Try manually:
        echo         nssm remove %SERVICE_NAME% confirm
    )
) else (
    echo       Service already removed.
)
echo.

:: ---- Step 3: Archive old wpdconverter/ folder ----
echo [3/4] Archiving old wpdconverter/ folder...
if exist "%OLD_DIR%" (
    set "ARCHIVE=%OLD_DIR%_retired_%DATE:~-4%%DATE:~4,2%%DATE:~7,2%"
    ren "%OLD_DIR%" "wpdconverter_retired_%DATE:~-4%%DATE:~4,2%%DATE:~7,2%" >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        echo       Renamed to wpdconverter_retired_%DATE:~-4%%DATE:~4,2%%DATE:~7,2%
    ) else (
        echo       WARNING: Could not rename folder. Rename manually.
    )
) else (
    echo       Folder not found - already archived or moved.
)
echo.

:: ---- Step 4: Archive network folders ----
echo [4/4] Archiving network inbox/outbox folders...
if exist "%NETWORK_INBOX%" (
    ren "%NETWORK_INBOX%" "WPD_INBOX_retired" >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        echo       Renamed %NETWORK_INBOX% to WPD_INBOX_retired
    ) else (
        echo       WARNING: Could not rename network inbox. May need manual cleanup.
    )
) else (
    echo       Network inbox not reachable or already archived.
)

if exist "%NETWORK_OUTBOX%" (
    ren "%NETWORK_OUTBOX%" "WPD_FORMATTED_retired" >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        echo       Renamed %NETWORK_OUTBOX% to WPD_FORMATTED_retired
    ) else (
        echo       WARNING: Could not rename network outbox. May need manual cleanup.
    )
) else (
    echo       Network outbox not reachable or already archived.
)

echo.
echo ============================================================
echo   NSSM watcher retired. The right-click converter is now
echo   the primary conversion method.
echo.
echo   Archived items (safe to delete once verified):
echo     - wpdconverter_retired_*  (old scripts and logs)
echo     - WPD_INBOX_retired       (network share)
echo     - WPD_FORMATTED_retired   (network share)
echo ============================================================
echo.
pause

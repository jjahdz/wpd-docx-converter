@echo off
:: WPD Converter Deployment Script
:: Run as Administrator. Installs LibreOffice (if needed), bundles
:: a portable Python, copies the converter to C:\Program Files\WPDConverter\,
:: applies the right-click context menu, and runs a sanity check.

setlocal enabledelayedexpansion
net session >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: This script must be run as Administrator.
    echo Right-click and choose "Run as administrator".
    pause
    exit /b 1
)

set "INSTALL_DIR=C:\Program Files\WPDConverter"
set "PYTHON_DIR=%INSTALL_DIR%\python"
set "SCRIPT_DIR=%~dp0"
set "LIBRE_PATH=C:\Program Files\LibreOffice\program\soffice.exe"
set "LIBRE_MSI=%SCRIPT_DIR%LibreOffice_25.8.2_Win_x86-64.msi"
set "PYTHON_ZIP=%SCRIPT_DIR%python-3.14.7-embed-amd64.zip"

echo ============================================================
echo   WPD Converter - Deployment
echo ============================================================
echo.

:: ---- Step 1: Check / Install LibreOffice ----
echo [1/4] Checking LibreOffice...
if exist "%LIBRE_PATH%" (
    echo       Found LibreOffice.
) else (
    echo       LibreOffice not found.
    if exist "%LIBRE_MSI%" (
        echo       Installing LibreOffice silently... this may take a few minutes.
        msiexec /i "%LIBRE_MSI%" /qn /norestart ADDLOCAL=ALL
        if not exist "%LIBRE_PATH%" (
            echo       ERROR: LibreOffice installation failed.
            pause
            exit /b 1
        )
        echo       LibreOffice installed.
    ) else (
        echo       ERROR: LibreOffice not found and no MSI installer available.
        echo       Place LibreOffice_25.8.2_Win_x86-64.msi next to this script.
        pause
        exit /b 1
    )
)
echo.

:: ---- Step 2: Install portable Python + converter files ----
echo [2/4] Installing converter to %INSTALL_DIR%...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

if not exist "%PYTHON_DIR%\python.exe" (
    if exist "%PYTHON_ZIP%" (
        echo       Extracting portable Python...
        powershell -NoProfile -Command "Expand-Archive -Path '%PYTHON_ZIP%' -DestinationPath '%PYTHON_DIR%' -Force"
        if not exist "%PYTHON_DIR%\python.exe" (
            echo       ERROR: Python extraction failed.
            pause
            exit /b 1
        )
        echo       Portable Python installed.
    ) else (
        echo       WARNING: Portable Python zip not found.
        echo       Checking for system Python...
        python --version >nul 2>&1
        if !ERRORLEVEL! neq 0 (
            echo       ERROR: No Python available. Place python-3.14.7-embed-amd64.zip next to this script.
            pause
            exit /b 1
        ) else (
            echo       Found system Python. Will use that.
        )
    )
) else (
    echo       Portable Python already installed.
)

copy /y "%SCRIPT_DIR%convert_wpd.py" "%INSTALL_DIR%\" >nul
copy /y "%SCRIPT_DIR%convert_wpd.bat" "%INSTALL_DIR%\" >nul
echo       Files copied.
echo.

:: ---- Step 3: Apply registry entry ----
echo [3/4] Adding right-click context menu...
reg import "%SCRIPT_DIR%convert_wpd_context_menu.reg" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo       WARNING: Registry import failed. Try running the .reg file manually.
) else (
    echo       Context menu registered.
)
echo.

:: ---- Step 4: Sanity check ----
echo [4/4] Running sanity check...
set "SANE=1"

if exist "%PYTHON_DIR%\python.exe" (
    set "PY=%PYTHON_DIR%\python.exe"
) else (
    set "PY=python"
)

"!PY!" "%INSTALL_DIR%\convert_wpd.py" 2>&1 | findstr /i "Usage" >nul
if %ERRORLEVEL% neq 0 (
    echo       FAIL: convert_wpd.py did not run correctly.
    set "SANE=0"
) else (
    echo       OK: convert_wpd.py runs.
)

if exist "%LIBRE_PATH%" (
    echo       OK: LibreOffice found at expected path.
) else (
    echo       FAIL: LibreOffice not at expected path.
    set "SANE=0"
)

reg query "HKEY_CLASSES_ROOT\WPDFile\shell\ConvertToDOCX" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    reg query "HKEY_CLASSES_ROOT\WP21Doc\shell\ConvertToDOCX" >nul 2>&1
    if !ERRORLEVEL! neq 0 (
        echo       FAIL: Context menu registry key not found.
        set "SANE=0"
    ) else (
        echo       OK: Context menu registry key present (WP21Doc).
    )
) else (
    echo       OK: Context menu registry key present.
)

echo.
if "!SANE!"=="1" (
    echo ============================================================
    echo   Deployment complete. Right-click any .wpd file to convert.
    echo ============================================================
) else (
    echo ============================================================
    echo   Deployment finished with warnings. Check errors above.
    echo ============================================================
)
echo.
pause

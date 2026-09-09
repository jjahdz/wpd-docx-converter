@echo off
:: WPD Converter Deployment Script
:: Run as Administrator. Installs LibreOffice (if needed), Python (if needed),
:: copies the converter to C:\Program Files\WPDConverter\, applies the
:: right-click context menu, and runs a sanity check.

setlocal enabledelayedexpansion
net session >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: This script must be run as Administrator.
    echo Right-click and choose "Run as administrator".
    pause
    exit /b 1
)

set "INSTALL_DIR=C:\Program Files\WPDConverter"
set "SCRIPT_DIR=%~dp0"
set "LIBRE_PATH=C:\Program Files\LibreOffice\program\soffice.exe"
set "LIBRE_MSI=%SCRIPT_DIR%LibreOffice_25.8.2_Win_x86-64.msi"

echo ============================================================
echo   WPD Converter - Deployment
echo ============================================================
echo.

:: ---- Step 1: Check / Install Python ----
echo [1/5] Checking Python...
python --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo       Python not found. Checking for installer...
    if exist "%SCRIPT_DIR%python-manager-25.0.msix" (
        echo       Installing Python via MSIX...
        powershell -NoProfile -Command "Add-AppxPackage -Path '%SCRIPT_DIR%python-manager-25.0.msix'"
        python --version >nul 2>&1
        if !ERRORLEVEL! neq 0 (
            echo       ERROR: Python installation failed. Install manually.
            pause
            exit /b 1
        )
        echo       Python installed.
    ) else (
        echo       ERROR: Python not found and no installer available.
        echo       Place python-manager-25.0.msix next to this script or install Python manually.
        pause
        exit /b 1
    )
) else (
    for /f "delims=" %%V in ('python --version 2^>^&1') do echo       Found %%V
)
echo.

:: ---- Step 2: Check / Install LibreOffice ----
echo [2/5] Checking LibreOffice...
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

:: ---- Step 3: Copy converter files ----
echo [3/5] Installing converter to %INSTALL_DIR%...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
copy /y "%SCRIPT_DIR%convert_wpd.py" "%INSTALL_DIR%\" >nul
copy /y "%SCRIPT_DIR%convert_wpd.bat" "%INSTALL_DIR%\" >nul
echo       Files copied.
echo.

:: ---- Step 4: Apply registry entry ----
echo [4/5] Adding right-click context menu...
reg import "%SCRIPT_DIR%convert_wpd_context_menu.reg" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo       WARNING: Registry import failed. Try running the .reg file manually.
) else (
    echo       Context menu registered.
)
echo.

:: ---- Step 5: Sanity check ----
echo [5/5] Running sanity check...
set "SANE=1"

python "%INSTALL_DIR%\convert_wpd.py" 2>&1 | findstr /i "Usage" >nul
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
    echo       FAIL: Context menu registry key not found.
    set "SANE=0"
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

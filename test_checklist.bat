@echo off
:: WPD Converter - Test Checklist
:: Run after deployment to verify everything works.
:: Requires a test .wpd file passed as argument.
::
:: Usage: test_checklist.bat "C:\path\to\test.wpd"

setlocal enabledelayedexpansion

set "INSTALL_DIR=C:\Program Files\WPDConverter"
set "LIBRE_PATH=C:\Program Files\LibreOffice\program\soffice.exe"
set "PASS=0"
set "FAIL=0"
set "SKIP=0"

echo ============================================================
echo   WPD Converter - Test Checklist
echo ============================================================
echo.

:: ---- Test 1: Python available ----
echo [Test 1] Python is installed and on PATH
python --version >nul 2>&1
if %ERRORLEVEL% equ 0 (
    for /f "delims=" %%V in ('python --version 2^>^&1') do echo          PASS: %%V
    set /a PASS+=1
) else (
    echo          FAIL: Python not found
    set /a FAIL+=1
)
echo.

:: ---- Test 2: LibreOffice installed ----
echo [Test 2] LibreOffice is installed
if exist "%LIBRE_PATH%" (
    echo          PASS: Found at %LIBRE_PATH%
    set /a PASS+=1
) else (
    echo          FAIL: Not found at %LIBRE_PATH%
    set /a FAIL+=1
)
echo.

:: ---- Test 3: Converter script installed ----
echo [Test 3] Converter script is installed
if exist "%INSTALL_DIR%\convert_wpd.py" (
    echo          PASS: %INSTALL_DIR%\convert_wpd.py exists
    set /a PASS+=1
) else (
    echo          FAIL: convert_wpd.py not found in %INSTALL_DIR%
    set /a FAIL+=1
)
echo.

:: ---- Test 4: Bat wrapper installed ----
echo [Test 4] Bat wrapper is installed
if exist "%INSTALL_DIR%\convert_wpd.bat" (
    echo          PASS: %INSTALL_DIR%\convert_wpd.bat exists
    set /a PASS+=1
) else (
    echo          FAIL: convert_wpd.bat not found in %INSTALL_DIR%
    set /a FAIL+=1
)
echo.

:: ---- Test 5: Context menu registry key ----
echo [Test 5] Right-click context menu is registered
reg query "HKEY_CLASSES_ROOT\WPDFile\shell\ConvertToDOCX\command" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo          PASS: Registry key present
    set /a PASS+=1
) else (
    echo          FAIL: Registry key not found
    set /a FAIL+=1
)
echo.

:: ---- Test 6: Convert a real .wpd file ----
echo [Test 6] Convert a real .wpd file
if "%~1"=="" (
    echo          SKIP: No test file provided. Pass a .wpd path as argument.
    set /a SKIP+=1
) else (
    if not exist "%~1" (
        echo          FAIL: Test file not found: %~1
        set /a FAIL+=1
    ) else (
        for /f "delims=" %%A in ('python "%INSTALL_DIR%\convert_wpd.py" "%~1" 2^>nul') do set "OUT6=%%A"
        if !ERRORLEVEL! equ 0 (
            if exist "!OUT6!" (
                echo          PASS: Created !OUT6!
                set /a PASS+=1
                set "FIRST_DOCX=!OUT6!"
            ) else (
                echo          FAIL: Script returned 0 but output not found
                set /a FAIL+=1
            )
        ) else (
            echo          FAIL: Conversion returned error code !ERRORLEVEL!
            set /a FAIL+=1
        )
    )
)
echo.

:: ---- Test 7: Duplicate name handling ----
echo [Test 7] Convert same file again (duplicate name handling)
if "%~1"=="" (
    echo          SKIP: No test file provided.
    set /a SKIP+=1
) else if not defined FIRST_DOCX (
    echo          SKIP: Test 6 did not produce output.
    set /a SKIP+=1
) else (
    for /f "delims=" %%A in ('python "%INSTALL_DIR%\convert_wpd.py" "%~1" 2^>nul') do set "OUT7=%%A"
    if !ERRORLEVEL! equ 0 (
        if "!OUT7!"=="!FIRST_DOCX!" (
            echo          FAIL: Same filename - timestamp rename did not work
            set /a FAIL+=1
        ) else (
            if exist "!OUT7!" (
                echo          PASS: Timestamped as !OUT7!
                set /a PASS+=1
            ) else (
                echo          FAIL: Script returned 0 but output not found
                set /a FAIL+=1
            )
        )
    ) else (
        echo          FAIL: Conversion returned error code !ERRORLEVEL!
        set /a FAIL+=1
    )
)
echo.

:: ---- Test 8: Bad file path handling ----
echo [Test 8] Reject nonexistent file gracefully
python "%INSTALL_DIR%\convert_wpd.py" "C:\nonexistent\fake.wpd" >nul 2>&1
if %ERRORLEVEL% equ 1 (
    echo          PASS: Exit code 1 for missing file
    set /a PASS+=1
) else (
    echo          FAIL: Expected exit code 1, got %ERRORLEVEL%
    set /a FAIL+=1
)
echo.

:: ---- Test 9: NSSM service is gone ----
echo [Test 9] Old NSSM service is not running
sc query wpdconverter >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo          PASS: Service not registered
    set /a PASS+=1
) else (
    sc query wpdconverter | findstr /i "STOPPED" >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        echo          WARN: Service exists but is stopped
        set /a PASS+=1
    ) else (
        echo          FAIL: Service is still running
        set /a FAIL+=1
    )
)
echo.

:: ---- Summary ----
echo ============================================================
echo   Results: !PASS! passed, !FAIL! failed, !SKIP! skipped
echo ============================================================

if !FAIL! equ 0 (
    if !SKIP! equ 0 (
        echo   All tests passed. Deployment verified.
    ) else (
        echo   No failures. Re-run with a .wpd file to complete all tests.
    )
) else (
    echo   Some tests failed. Review output above.
)
echo.

:: ---- Cleanup prompt ----
if defined FIRST_DOCX (
    echo   Test files created:
    if exist "!FIRST_DOCX!" echo     - !FIRST_DOCX!
    if defined OUT7 if exist "!OUT7!" echo     - !OUT7!
    echo.
    set /p "CLEAN=Delete test output files? (y/n): "
    if /i "!CLEAN!"=="y" (
        if exist "!FIRST_DOCX!" del "!FIRST_DOCX!"
        if defined OUT7 if exist "!OUT7!" del "!OUT7!"
        echo   Cleaned up.
    )
)
echo.
pause

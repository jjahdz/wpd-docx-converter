@echo off
:: Wrapper called by the right-click context menu.
:: Runs the Python converter and shows a Windows toast notification.
:: Uses portable Python bundled in the install directory, falls back to system Python.

setlocal enabledelayedexpansion

set "INSTALL_DIR=C:\Program Files\WPDConverter"
set "TMPFILE=%TEMP%\docx_convert_result.txt"

if exist "%INSTALL_DIR%\python\python.exe" (
    set "PY=%INSTALL_DIR%\python\python.exe"
) else (
    set "PY=python"
)

:: Run the converter, capture stdout to temp file.
"!PY!" "%INSTALL_DIR%\convert_wpd.py" "%~1" > "%TMPFILE%" 2>&1
set "EXITCODE=%ERRORLEVEL%"

if %EXITCODE% equ 0 (
    set /p RESULT=<"%TMPFILE%"
    for %%F in ("!RESULT!") do set "FILENAME=%%~nxF"
    powershell -NoProfile -Command "[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null; $xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent(0); $text = $xml.GetElementsByTagName('text'); $text.Item(0).AppendChild($xml.CreateTextNode('Converted: !FILENAME!')) | Out-Null; [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('DOCX Converter').Show([Windows.UI.Notifications.ToastNotification]::new($xml))"
) else (
    if %EXITCODE% equ 2 (
        set "MSG=Conversion failed - LibreOffice not found"
    ) else (
        set "MSG=Conversion failed for %~nx1"
    )
    powershell -NoProfile -Command "[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null; $xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent(0); $text = $xml.GetElementsByTagName('text'); $text.Item(0).AppendChild($xml.CreateTextNode('!MSG!')) | Out-Null; [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('DOCX Converter').Show([Windows.UI.Notifications.ToastNotification]::new($xml))"
    echo.
    echo ERROR OUTPUT:
    type "%TMPFILE%"
    echo.
    pause
)

del "%TMPFILE%" >nul 2>&1
endlocal

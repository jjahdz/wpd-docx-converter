@echo off
:: Wrapper called by the right-click context menu.
:: Runs the Python converter and shows a Windows toast notification.

setlocal enabledelayedexpansion

:: Run the converter — stdout has the output path on success, stderr has errors.
for /f "delims=" %%A in ('python "C:\Program Files\WPDConverter\convert_wpd.py" "%~1" 2^>nul') do set "RESULT=%%A"

if %ERRORLEVEL% equ 0 (
    for %%F in ("!RESULT!") do set "FILENAME=%%~nxF"
    powershell -NoProfile -Command "[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null; $xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent(0); $text = $xml.GetElementsByTagName('text'); $text.Item(0).AppendChild($xml.CreateTextNode('Converted: !FILENAME!')) | Out-Null; [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('WPD Converter').Show([Windows.UI.Notifications.ToastNotification]::new($xml))"
) else (
    if %ERRORLEVEL% equ 2 (
        set "MSG=Conversion failed - LibreOffice not found"
    ) else (
        set "MSG=Conversion failed for %~nx1"
    )
    powershell -NoProfile -Command "[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null; $xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent(0); $text = $xml.GetElementsByTagName('text'); $text.Item(0).AppendChild($xml.CreateTextNode('!MSG!')) | Out-Null; [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('WPD Converter').Show([Windows.UI.Notifications.ToastNotification]::new($xml))"
)

endlocal

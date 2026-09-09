@echo off
:: Wrapper called by the right-click context menu.
:: Runs the Python converter and will show a toast notification (Phase 3).
python "C:\Program Files\WPDConverter\convert_wpd.py" "%~1"

# DOCX Converter — Setup & Deployment Guide

## Overview

Converts WordPerfect (`.wpd`) and OpenDocument (`.odt`) files to `.docx` via a right-click context menu using LibreOffice headless. One-click conversion with toast notifications.

---

## Prerequisites (bundled in repo)

- **Python 3.x** — `python-3.14.7-embed-amd64.zip` (portable, no install needed)
- **LibreOffice** — `LibreOffice_25.8.2_Win_x86-64.msi`

Both are set up automatically by `deploy.bat`.

---

## Deploying to a Workstation

### Option A: From network share (recommended)

1. Copy the project folder to your network share:
   ```
   xcopy "C:\Users\administrator\Music\Workspace" "\\Win-em2un8j7eiv\i\17\WPDConverter_Deploy\" /E /I /Y
   ```

2. On each workstation, open an **Administrator Command Prompt** and run:
   ```
   "\\Win-em2un8j7eiv\i\17\WPDConverter_Deploy\deploy.bat"
   ```

### Option B: Remote deployment via PowerShell

If PowerShell remoting is enabled on the target machines:
```powershell
Invoke-Command -ComputerName PC1,PC2,PC3 -ScriptBlock {
    Start-Process cmd -ArgumentList '/c "\\Win-em2un8j7eiv\i\17\WPDConverter_Deploy\deploy.bat"' -Verb RunAs -Wait
}
```

### Option C: USB / local copy

1. Copy the entire project folder to the target machine.
2. Open an **Administrator Command Prompt** in the copied folder.
3. Run `deploy.bat`.

---

## What deploy.bat Does

| Step | Action |
|------|--------|
| 1 | Checks for LibreOffice; installs from bundled `.msi` if missing |
| 2 | Extracts portable Python; copies converter files to `C:\Program Files\WPDConverter\` |
| 3 | Imports `convert_wpd_context_menu.reg` (adds right-click menu for `.wpd` and `.odt`) |
| 4 | Runs a sanity check (script runs, LibreOffice exists, registry key present) |

---

## Using the Converter

1. Right-click any `.wpd` or `.odt` file.
2. Click **"Show more options"** (Windows 11 only — not needed on Windows 10).
3. Click **"Convert to DOCX"**.
4. A toast notification confirms success or reports an error.
5. The `.docx` appears in the same folder as the original.

If a `.docx` with the same name already exists, the output is automatically timestamped (e.g. `document_2026-09-09_114530.docx`).

---

## Supported File Types

| Extension | Format | Notes |
|-----------|--------|-------|
| `.wpd` | WordPerfect | Legacy word processor format |
| `.odt` | OpenDocument Text | LibreOffice / OpenOffice native format |

Both are converted to `.docx` (Microsoft Word) format.

---

## Retiring the Old NSSM Watcher

After confirming the right-click converter works on a machine, run as Administrator:
```
retire_nssm.bat
```

This will:
1. Stop the `wpdconverter` NSSM service.
2. Remove the service registration.
3. Rename `wpdconverter/` to `wpdconverter_retired_YYYYMMDD`.
4. Rename network inbox/outbox folders with a `_retired` suffix (if reachable).

Nothing is deleted — everything is renamed for safe archival.

---

## Verifying a Deployment

Run with a test file:
```
test_checklist.bat "C:\path\to\test.wpd"
```

### Tests performed

| # | Check |
|---|-------|
| 1 | Python is installed and on PATH |
| 2 | LibreOffice is installed |
| 3 | `convert_wpd.py` in `C:\Program Files\WPDConverter\` |
| 4 | `convert_wpd.bat` in `C:\Program Files\WPDConverter\` |
| 5 | Right-click registry key exists |
| 6 | Convert a real `.wpd` file |
| 7 | Convert same file again (timestamp rename works) |
| 8 | Reject nonexistent file gracefully |
| 9 | Old NSSM service is not running |

---

## File Inventory

| File | Purpose |
|------|---------|
| `convert_wpd.py` | Core converter script (`.wpd` and `.odt` to `.docx`) |
| `convert_wpd.bat` | Wrapper with toast notifications |
| `convert_wpd_context_menu.reg` | Right-click context menu for `.wpd` and `.odt` files |
| `deploy.bat` | One-shot workstation deployment |
| `retire_nssm.bat` | Retire old NSSM watcher service |
| `test_checklist.bat` | Post-deployment verification |

---

## Troubleshooting

**"Convert to DOCX" not in context menu**
- Run `deploy.bat` as Administrator again to re-apply the registry.
- On Windows 11, the entry is under "Show more options".

**Conversion fails silently**
- Check that LibreOffice is installed: `"C:\Program Files\LibreOffice\program\soffice.exe"` should exist.
- Run the converter manually to see errors:
  ```
  "C:\Program Files\WPDConverter\python\python.exe" "C:\Program Files\WPDConverter\convert_wpd.py" "C:\path\to\file.wpd"
  ```

**Toast notification doesn't appear**
- Check Windows notification settings: Settings → System → Notifications.
- Ensure "DOCX Converter" is not in the blocked list.

**NSSM service keeps restarting**
- Run `retire_nssm.bat` as Administrator.
- If that fails, manually remove: `nssm remove wpdconverter confirm`

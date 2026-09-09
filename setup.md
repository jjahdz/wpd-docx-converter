# WPD Converter — Setup & Deployment Guide

## Overview

Converts WordPerfect (`.wpd`) files to `.docx` via a right-click context menu using LibreOffice headless. One-click conversion with toast notifications.

---

## Prerequisites (bundled in repo)

- **Python 3.x** — `python-manager-25.0.msix`
- **LibreOffice** — `LibreOffice_25.8.2_Win_x86-64.msi`

Both are installed automatically by `deploy.bat` if not already present.

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
| 1 | Checks for Python; installs from bundled `.msix` if missing |
| 2 | Checks for LibreOffice; installs from bundled `.msi` if missing |
| 3 | Copies `convert_wpd.py` and `convert_wpd.bat` to `C:\Program Files\WPDConverter\` |
| 4 | Imports `convert_wpd_context_menu.reg` (adds right-click menu entry) |
| 5 | Runs a 3-point sanity check (script runs, LibreOffice exists, registry key present) |

---

## Using the Converter

1. Right-click any `.wpd` file.
2. Click **"Show more options"** (Windows 11 only — not needed on Windows 10).
3. Click **"Convert to DOCX"**.
4. A toast notification confirms success or reports an error.
5. The `.docx` appears in the same folder as the original.

If a `.docx` with the same name already exists, the output is automatically timestamped (e.g. `document_2026-09-09_114530.docx`).

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

Run with a test `.wpd` file:
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
| `convert_wpd.py` | Core converter script (Python) |
| `convert_wpd.bat` | Wrapper with toast notifications |
| `convert_wpd_context_menu.reg` | Right-click context menu registry entries |
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
  python "C:\Program Files\WPDConverter\convert_wpd.py" "C:\path\to\file.wpd"
  ```

**Toast notification doesn't appear**
- Check Windows notification settings: Settings → System → Notifications.
- Ensure "WPD Converter" is not in the blocked list.

**NSSM service keeps restarting**
- Run `retire_nssm.bat` as Administrator.
- If that fails, manually remove: `nssm remove wpdconverter confirm`

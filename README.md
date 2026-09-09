# WPD / ODT to DOCX Converter

Right-click context menu converter for WordPerfect (`.wpd`) and OpenDocument (`.odt`) files on Windows. Converts to `.docx` using LibreOffice headless with toast notifications.

## Quick Start

1. Run `deploy.bat` as Administrator on each workstation.
2. Right-click any `.wpd` or `.odt` file → **Show more options** → **Convert to DOCX**.

## Files

| File | Purpose |
|------|---------|
| `convert_wpd.py` | Core converter script (handles `.wpd` and `.odt`) |
| `convert_wpd.bat` | Wrapper with toast notifications |
| `convert_wpd_context_menu.reg` | Right-click context menu registry entries |
| `deploy.bat` | One-shot workstation deployment |
| `retire_nssm.bat` | Retire old NSSM watcher service |
| `test_checklist.bat` | Post-deployment verification |

## Deployment

See [setup.md](setup.md) for full deployment instructions, troubleshooting, and network share rollout options.

#!/usr/bin/env python3
"""
Convert a .wpd or .odt file to .docx using LibreOffice headless.

Usage:
    python convert_wpd.py "C:\\path\\to\\file.wpd"
    python convert_wpd.py "C:\\path\\to\\file.odt"

The .docx is placed next to the original. If a .docx with the same name
already exists, the output is timestamped (e.g. document_2026-09-09_114530.docx).

Exit codes:
    0  success
    1  bad arguments or file not found
    2  LibreOffice not found
    3  conversion failed
"""

import os
import sys
import subprocess
import shutil
from datetime import datetime

LIBREOFFICE_PATH = r"C:\Program Files\LibreOffice\program\soffice.exe"


def find_libreoffice():
    if os.path.isfile(LIBREOFFICE_PATH):
        return LIBREOFFICE_PATH
    for candidate in [
        os.path.join(os.environ.get("PROGRAMFILES", ""), "LibreOffice", "program", "soffice.exe"),
        os.path.join(os.environ.get("PROGRAMFILES(X86)", ""), "LibreOffice", "program", "soffice.exe"),
    ]:
        if candidate and os.path.isfile(candidate):
            return candidate
    return None


def unique_path(dest):
    """If dest already exists, insert a timestamp before the extension."""
    if not os.path.exists(dest):
        return dest
    base, ext = os.path.splitext(dest)
    stamp = datetime.now().strftime("%Y-%m-%d_%H%M%S")
    return f"{base}_{stamp}{ext}"


def convert(wpd_path):
    wpd_path = os.path.abspath(wpd_path)

    if not os.path.isfile(wpd_path):
        print(f"File not found: {wpd_path}", file=sys.stderr)
        return 1

    SUPPORTED = (".wpd", ".odt")
    if not any(wpd_path.lower().endswith(ext) for ext in SUPPORTED):
        print(f"Unsupported file type: {wpd_path}", file=sys.stderr)
        return 1

    soffice = find_libreoffice()
    if not soffice:
        print("LibreOffice not found. Install it or check the path.", file=sys.stderr)
        return 2

    out_dir = os.path.dirname(wpd_path)
    stem = os.path.splitext(os.path.basename(wpd_path))[0]
    default_dest = os.path.join(out_dir, stem + ".docx")

    tmp_dir = os.path.join(out_dir, f".wpd_conv_{os.getpid()}")
    os.makedirs(tmp_dir, exist_ok=True)

    try:
        result = subprocess.run(
            [soffice, "--headless", "--convert-to", "docx", "--outdir", tmp_dir, wpd_path],
            capture_output=True,
            timeout=120,
        )

        tmp_output = os.path.join(tmp_dir, stem + ".docx")
        if not os.path.isfile(tmp_output):
            stderr_text = result.stderr.decode(errors="replace").strip()
            print(f"Conversion failed. LibreOffice stderr:\n{stderr_text}", file=sys.stderr)
            return 3

        final_dest = unique_path(default_dest)
        shutil.move(tmp_output, final_dest)
        print(final_dest)
        return 0

    except subprocess.TimeoutExpired:
        print("Conversion timed out after 120 seconds.", file=sys.stderr)
        return 3
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        return 3
    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <file.wpd>", file=sys.stderr)
        sys.exit(1)
    sys.exit(convert(sys.argv[1]))

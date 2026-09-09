#!/usr/bin/env python3
"""
Network-level WPD to DOCX converter.
Watches a shared network drive and converts .wpd files for all users.
Processes files of ANY age (not just today's files).
"""

import os
import time
import shutil
import logging
import subprocess
from datetime import datetime
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from threading import Lock

# ============ NETWORK DRIVE CONFIG ============
# Replace these paths with your actual network drive paths
WATCH_FOLDER = r"\\Win-em2un8j7eiv\i\WPD_INBOX"         #<----OLD PATHS
BASE_DIR = r"\\Win-em2un8j7eiv\i\WPD_FORMATTED"         #<----OLD PATHS
#WATCH_FOLDER = r"\\192.168.160.10\i\WPD_INBOX"         #<----NEW PATHS
#BASE_DIR = r"\\192.168.160.10\i\WPD_FORMATTED"         #<----NEW PATHS
BACKUP_FOLDER = os.path.join(BASE_DIR, "backup")
CONVERTED_FOLDER = os.path.join(BASE_DIR, "converted")
LOG_FILE = os.path.join(BASE_DIR, "converter.log")

# Path to LibreOffice executable
LIBREOFFICE_PATH = r"C:\Program Files\LibreOffice\program\soffice.exe"
# =============================================

# Runtime helpers
_processing = set()
_processing_lock = Lock()

# Setup logging
os.makedirs(BASE_DIR, exist_ok=True)
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
console = logging.StreamHandler()
console.setLevel(logging.INFO)
console.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(message)s"))
logging.getLogger().addHandler(console)


def file_is_stable(path, checks=3, interval=0.5, timeout=30):
    """
    Wait until the file size is stable for `checks` consecutive checks.
    Returns True if stable within timeout, False otherwise.
    """
    start = time.time()
    last_size = -1
    stable_count = 0
    while time.time() - start < timeout:
        try:
            size = os.path.getsize(path)
        except (OSError, FileNotFoundError):
            return False
        if size == last_size:
            stable_count += 1
            if stable_count >= checks:
                return True
        else:
            stable_count = 0
            last_size = size
        time.sleep(interval)
    return False


def backup_file(src_path):
    """Copy the original file to the BACKUP_FOLDER with a timestamped name."""
    os.makedirs(BACKUP_FOLDER, exist_ok=True)
    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    basename = os.path.basename(src_path)
    dest = os.path.join(BACKUP_FOLDER, f"{timestamp}_{basename}")
    shutil.copy2(src_path, dest)
    logging.info(f"Backed up: {src_path} -> {dest}")
    return dest


def convert_with_libreoffice(src_path):
    """Convert src_path (.wpd) to .docx using LibreOffice; place result in CONVERTED_FOLDER."""
    os.makedirs(CONVERTED_FOLDER, exist_ok=True)
    try:
        subprocess.run(
            [LIBREOFFICE_PATH, "--headless", "--convert-to", "docx", "--outdir", CONVERTED_FOLDER, src_path],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        base = os.path.splitext(os.path.basename(src_path))[0] + ".docx"
        converted_path = os.path.join(CONVERTED_FOLDER, base)
        if os.path.exists(converted_path):
            logging.info(f"Converted: {src_path} -> {converted_path}")
            return converted_path
        else:
            logging.warning(f"Conversion reported success but output not found: {converted_path}")
            return None
    except subprocess.CalledProcessError as e:
        logging.error(f"LibreOffice conversion failed for {src_path}: {e}")
        return None
    except FileNotFoundError:
        logging.error(f"LibreOffice executable not found at '{LIBREOFFICE_PATH}'. Check LIBREOFFICE_PATH.")
        return None


def process_new_file(src_path):
    """Main pipeline invoked when a new .wpd file is detected."""
    # Avoid duplicate processing
    with _processing_lock:
        if src_path in _processing:
            logging.debug(f"Already processing: {src_path}")
            return
        _processing.add(src_path)

    try:
        logging.info(f"Detected file: {src_path}")

        # Wait for file to be fully written (avoid partial upload conversion)
        if not file_is_stable(src_path):
            logging.warning(f"File not stable or not found: {src_path} -- skipping for now.")
            return

        # NOTE: Date check removed - processes files of any age

        # Backup original
        backup_file(src_path)

        # Convert
        convert_with_libreoffice(src_path)

    except Exception as e:
        logging.error(f"Error processing {src_path}: {e}")

    finally:
        with _processing_lock:
            _processing.discard(src_path)


class WPDHandler(FileSystemEventHandler):
    """Watchdog event handler for created / moved files."""

    def on_created(self, event):
        if event.is_directory:
            return
        path = event.src_path
        if path.lower().endswith(".wpd"):
            time.sleep(0.2)
            process_new_file(path)

    def on_moved(self, event):
        if event.is_directory:
            return
        dest_path = event.dest_path
        if dest_path.lower().endswith(".wpd"):
            time.sleep(0.2)
            process_new_file(dest_path)


def main():
    logging.info("=" * 60)
    logging.info("Starting WPD -> DOCX Network Converter")
    logging.info(f"Watching: {WATCH_FOLDER}")
    logging.info(f"Backups: {BACKUP_FOLDER}")
    logging.info(f"Converted: {CONVERTED_FOLDER}")
    logging.info("Processes files of ANY age")
    logging.info("=" * 60)

    if not os.path.exists(WATCH_FOLDER):
        logging.error(f"Watch folder does not exist: {WATCH_FOLDER}")
        logging.error("Please check the WATCH_FOLDER path and try again.")
        return

    observer = Observer()
    handler = WPDHandler()

    observer.schedule(handler, WATCH_FOLDER, recursive=False)
    observer.start()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        logging.info("Shutting down watcher...")
        observer.stop()
    observer.join()


if __name__ == "__main__":
    main()
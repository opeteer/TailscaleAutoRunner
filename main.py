#!/usr/bin/env python3
"""
Tailscale AutoRunner
Lightweight, reliable daemon for Linux systems to continuously monitor
and maintain your Tailscale network connection.
"""
import argparse
import json
import logging
import os
import shutil
import signal
import subprocess
import sys
import time

# Konfigurasi default
DEFAULT_CHECK_INTERVAL = int(os.environ.get("CHECK_INTERVAL", 30))
DEFAULT_TIMEOUT = int(os.environ.get("CMD_TIMEOUT", 15))

# Konfigurasi logging standar
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")


def find_tailscale_binary(custom_path=None):
    """
    Mencari lokasi binary tailscale di PATH atau direktori sistem umum
    untuk portabilitas di berbagai distribusi Linux.
    """
    if custom_path:
        if os.path.isfile(custom_path) and os.access(custom_path, os.X_OK):
            return custom_path
        raise FileNotFoundError(f"Binary tailscale kustom tidak ditemukan: {custom_path}")

    # Cek environment variable TAILSCALE_BIN
    env_path = os.environ.get("TAILSCALE_BIN")
    if env_path and os.path.isfile(env_path) and os.access(env_path, os.X_OK):
        return env_path

    # Cari di PATH lingkungan saat ini
    bin_path = shutil.which("tailscale")
    if bin_path:
        return bin_path

    # Fallback ke jalur-jalur umum pada berbagai distro Linux
    common_paths = [
        "/usr/bin/tailscale",
        "/usr/sbin/tailscale",
        "/usr/local/bin/tailscale",
        "/snap/bin/tailscale",
        "/bin/tailscale",
        "/sbin/tailscale",
    ]
    for path in common_paths:
        if os.path.isfile(path) and os.access(path, os.X_OK):
            return path

    raise FileNotFoundError("Aplikasi 'tailscale' tidak ditemukan di sistem. Harap install terlebih dahulu.")


def check_and_reconnect(tailscale_bin=None, timeout=DEFAULT_TIMEOUT):
    """
    Mengecek status Tailscale via JSON output dan melakukan
    'tailscale up' otomatis bila koneksi terhenti atau putus.
    """
    try:
        if not tailscale_bin:
            tailscale_bin = find_tailscale_binary()

        # Menjalankan perintah tailscale status --json untuk mendapatkan format data yang mudah diolah
        result = subprocess.run(
            [tailscale_bin, "status", "--json"],
            capture_output=True,
            text=True,
            timeout=timeout,
        )

        # Jika perintah error (misal tailscaled service mati)
        if result.returncode != 0:
            err_output = (result.stderr or result.stdout or "").strip()
            if "failed to connect to local tailscaled" in err_output.lower():
                logging.warning("Daemon tailscaled tidak berjalan. Harap pastikan service tailscaled sudah aktif.")
            else:
                logging.error(f"Gagal mengecek status tailscale: {err_output}")
            return False

        try:
            status = json.loads(result.stdout)
        except json.JSONDecodeError:
            logging.error("Gagal membaca output JSON dari tailscale status.")
            return False

        backend_state = status.get("BackendState", "Unknown")

        # Jika tailscale dalam keadaan terhenti, putus, atau butuh login
        if backend_state in ["Stopped", "NeedsLogin"]:
            logging.info(f"Koneksi terputus (Status: {backend_state}). Menjalankan '{tailscale_bin} up'...")

            # Menjalankan tailscale up
            up_result = subprocess.run(
                [tailscale_bin, "up"],
                capture_output=True,
                text=True,
                timeout=timeout * 2,
            )

            if up_result.returncode == 0:
                logging.info("Tailscale berhasil dihubungkan kembali.")
                return True
            else:
                logging.error(f"Gagal menjalankan tailscale up: {up_result.stderr.strip()}")
                return False
        elif backend_state == "Running":
            logging.debug("Koneksi Tailscale aktif (Running).")
            return True
        else:
            logging.info(f"Status Tailscale: {backend_state}")
            return True

    except subprocess.TimeoutExpired:
        logging.error(f"Pengecekan waktu habis (timeout {timeout} detik) saat menghubungi Tailscale.")
        return False
    except FileNotFoundError as e:
        logging.error(str(e))
        return False
    except Exception as e:
        logging.error(f"Terjadi kesalahan tidak terduga: {e}")
        return False


def setup_signal_handlers():
    """Menangani sinyal terminasi dengan bersih (graceful shutdown)."""
    def handle_signal(sig, frame):
        sig_name = signal.Signals(sig).name
        logging.info(f"Menerima sinyal {sig_name}. Menghentikan Tailscale AutoRunner secara aman...")
        sys.exit(0)

    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)


def parse_arguments():
    """Mengolah argumen command-line untuk fleksibilitas konfigurasi."""
    parser = argparse.ArgumentParser(
        description="Tailscale AutoRunner - Daemon pemantau dan pemulih otomatis koneksi Tailscale di Linux."
    )
    parser.add_argument(
        "-i", "--interval",
        type=int,
        default=DEFAULT_CHECK_INTERVAL,
        help=f"Interval waktu pengecekan dalam detik (default: {DEFAULT_CHECK_INTERVAL})",
    )
    parser.add_argument(
        "--once",
        action="store_true",
        help="Jalankan pemeriksaan satu kali saja lalu keluar (berguna untuk cron job)",
    )
    parser.add_argument(
        "--tailscale-bin",
        type=str,
        default=None,
        help="Jalur kustom ke binary tailscale (opsional)",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=DEFAULT_TIMEOUT,
        help=f"Batas waktu tunggu (timeout) perintah dalam detik (default: {DEFAULT_TIMEOUT})",
    )
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Aktifkan logging verbose (tingkat DEBUG)",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_arguments()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    setup_signal_handlers()

    # Validasi awal ketersediaan binary
    try:
        resolved_bin = find_tailscale_binary(args.tailscale_bin)
        logging.debug(f"Menggunakan binary Tailscale: {resolved_bin}")
    except FileNotFoundError as err:
        logging.error(str(err))
        sys.exit(1)

    if args.once:
        logging.info("Menjalankan pemeriksaan koneksi satu kali (--once)...")
        success = check_and_reconnect(tailscale_bin=resolved_bin, timeout=args.timeout)
        sys.exit(0 if success else 1)

    logging.info(f"Memulai Tailscale AutoRunner (interval: {args.interval} detik)...")
    while True:
        check_and_reconnect(tailscale_bin=resolved_bin, timeout=args.timeout)
        time.sleep(args.interval)

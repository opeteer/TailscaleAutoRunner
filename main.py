#!/usr/bin/env python3
import subprocess
import time
import json
import logging
import sys

# Konfigurasi logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

CHECK_INTERVAL = 30  # Interval pengecekan (dalam detik)

def check_and_reconnect():
    try:
        # Menjalankan perintah tailscale status --json untuk mendapatkan format data yang mudah diolah
        result = subprocess.run(['tailscale', 'status', '--json'], capture_output=True, text=True)
        
        # Jika perintah error (misal tailscaled service mati)
        if result.returncode != 0:
            if "failed to connect to local tailscaled" in result.stderr or "failed to connect to local tailscaled" in result.stdout:
                logging.warning("Daemon tailscaled tidak berjalan. Harap pastikan service tailscaled (systemctl start tailscaled) sudah aktif.")
            else:
                logging.error(f"Gagal mengecek status tailscale: {result.stderr.strip()}")
            return

        try:
            status = json.loads(result.stdout)
        except json.JSONDecodeError:
            logging.error("Gagal membaca output JSON dari tailscale status.")
            return

        backend_state = status.get('BackendState', 'Unknown')
        
        # Jika tailscale dalam keadaan terhenti, putus, atau butuh login
        if backend_state in ['Stopped', 'NeedsLogin']:
            logging.info(f"Koneksi terputus (Status: {backend_state}). Menjalankan 'tailscale up'...")
            
            # Menjalankan tailscale up
            up_result = subprocess.run(['tailscale', 'up'], capture_output=True, text=True)
            
            if up_result.returncode == 0:
                logging.info("Tailscale berhasil dihubungkan kembali.")
            else:
                logging.error(f"Gagal menjalankan tailscale up: {up_result.stderr.strip()}")
                
    except FileNotFoundError:
        logging.error("Aplikasi 'tailscale' tidak ditemukan di sistem. Harap install terlebih dahulu.")
    except Exception as e:
        logging.error(f"Terjadi kesalahan tidak terduga: {e}")

if __name__ == "__main__":
    logging.info("Memulai Tailscale AutoRunner...")
    while True:
        check_and_reconnect()
        time.sleep(CHECK_INTERVAL)

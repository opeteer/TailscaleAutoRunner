#!/bin/bash

# Memastikan script dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then
  echo "Harap jalankan script ini sebagai root (gunakan: sudo ./install.sh)"
  exit 1
fi

echo "Menginstal Tailscale AutoRunner sebagai background service..."

# Memberikan hak akses eksekusi pada script utama
chmod +x /home/opeteer/TailscaleAutoRunner/main.py

# Menyalin file service ke systemd
cp /home/opeteer/TailscaleAutoRunner/tailscale-autorunner.service /etc/systemd/system/

# Memuat ulang daemon systemd
systemctl daemon-reload

# Mengaktifkan dan memulai service
systemctl enable tailscale-autorunner.service
systemctl restart tailscale-autorunner.service

echo "Instalasi selesai! Service tailscale-autorunner sedang berjalan."
echo "Gunakan perintah berikut untuk mengecek log (realtime):"
echo "  sudo journalctl -u tailscale-autorunner -f"

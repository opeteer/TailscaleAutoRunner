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

# Mengaktifkan (auto-start saat boot) dan menjalankan service secara langsung
systemctl enable tailscale-autorunner.service
systemctl restart tailscale-autorunner.service

echo "Instalasi selesai! Service tailscale-autorunner telah di-enable untuk otomatis berjalan saat booting."
echo "Status service saat ini:"
systemctl status tailscale-autorunner.service --no-pager

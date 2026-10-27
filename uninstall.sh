#!/bin/bash
# ==============================================================================
# Tailscale AutoRunner - Uninstaller
# Menghapus service dan file yang telah dipasang di sistem
# ==============================================================================

set -e

for arg in "$@"; do
  if [ "$arg" = "-h" ] || [ "$arg" = "--help" ]; then
    echo "Penggunaan: sudo ./uninstall.sh"
    echo "Mencopot Tailscale AutoRunner dan menghapus service dari sistem."
    exit 0
  fi
done

if [ "$(id -u)" -ne 0 ]; then
  echo "[!] Harap jalankan script ini sebagai root (gunakan: sudo ./uninstall.sh)"
  exit 1
fi

echo "==> Menghapus Tailscale AutoRunner..."

# 1. Hentikan dan hapus service systemd jika ada
if [ -f /etc/systemd/system/tailscale-autorunner.service ]; then
  echo "    [-] Menghentikan dan menonaktifkan service systemd..."
  systemctl stop tailscale-autorunner.service 2>/dev/null || true
  systemctl disable tailscale-autorunner.service 2>/dev/null || true
  rm -f /etc/systemd/system/tailscale-autorunner.service
  systemctl daemon-reload 2>/dev/null || true
fi

# 2. Hentikan dan hapus service OpenRC jika ada
if [ -f /etc/init.d/tailscale-autorunner ]; then
  echo "    [-] Menghentikan dan menonaktifkan service OpenRC..."
  rc-service tailscale-autorunner stop 2>/dev/null || true
  rc-update del tailscale-autorunner default 2>/dev/null || true
  rm -f /etc/init.d/tailscale-autorunner
fi

# 3. Hentikan dan hapus service runit jika ada
if [ -e /var/service/tailscale-autorunner ]; then
  echo "    [-] Menghapus symlink service runit..."
  rm -f /var/service/tailscale-autorunner
fi
if [ -d /etc/sv/tailscale-autorunner ]; then
  echo "    [-] Menghapus definisi service runit..."
  rm -rf /etc/sv/tailscale-autorunner
fi

# 4. Hapus executable binary
for path in /usr/local/bin/tailscale-autorunner /usr/bin/tailscale-autorunner; do
  if [ -f "$path" ]; then
    echo "    [-] Menghapus binary: $path"
    rm -f "$path"
  fi
done

echo ""
echo "[OK] Tailscale AutoRunner berhasil dicopot (uninstalled) dari sistem."

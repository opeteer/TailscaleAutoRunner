#!/bin/bash
# ==============================================================================
# Tailscale AutoRunner - Installer
# Kompatibel dengan berbagai distribusi Linux (systemd, OpenRC, runit, dll.)
# ==============================================================================

set -e

# Tampilkan bantuan jika diminta (bisa tanpa root)
for arg in "$@"; do
  if [ "$arg" = "-h" ] || [ "$arg" = "--help" ]; then
    echo "Penggunaan: sudo ./install.sh [opsi]"
    echo "Opsi:"
    echo "  --bin-dir=<path>   Direktori target instalasi binary (default: /usr/local/bin)"
    echo "  --no-start         Hanya pasang file tanpa langsung menjalankan service"
    echo "  -h, --help         Tampilkan bantuan ini"
    exit 0
  fi
done

# Memastikan script dijalankan sebagai root
if [ "$(id -u)" -ne 0 ]; then
  echo "[!] Harap jalankan script ini sebagai root (gunakan: sudo ./install.sh)"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="/usr/local/bin"
[ ! -d "$BIN_DIR" ] && BIN_DIR="/usr/bin"

# Parse opsi jika ada
START_SERVICE=true
while [ $# -gt 0 ]; do
  case "$1" in
    --bin-dir=*)
      BIN_DIR="${1#*=}"
      ;;
    --no-start)
      START_SERVICE=false
      ;;
    -h|--help)
      echo "Penggunaan: sudo ./install.sh [opsi]"
      echo "Opsi:"
      echo "  --bin-dir=<path>   Direktori target instalasi binary (default: /usr/local/bin)"
      echo "  --no-start         Hanya pasang file tanpa langsung menjalankan service"
      echo "  -h, --help         Tampilkan bantuan ini"
      exit 0
      ;;
    *)
      echo "Opsi tidak dikenal: $1"
      exit 1
      ;;
  esac
  shift
done

echo "==> Memeriksa kebutuhan sistem..."

# Cek Python 3
if ! command -v python3 >/dev/null 2>&1; then
  echo "[X] Error: Python 3 tidak ditemukan di sistem. Harap install Python 3 terlebih dahulu."
  exit 1
fi
echo "    [v] Python 3 terdeteksi: $(command -v python3)"

# Cek Tailscale
if command -v tailscale >/dev/null 2>&1; then
  echo "    [v] Tailscale terdeteksi: $(command -v tailscale)"
else
  echo "    [!] Peringatan: Perintah 'tailscale' belum terdeteksi di PATH saat ini."
  echo "        Pastikan Tailscale telah terinstal dan terkonfigurasi di sistem."
fi

# 1. Pasang file binary executable
echo "==> Memasang file executable ke $BIN_DIR/tailscale-autorunner..."
mkdir -p "$BIN_DIR"
install -m 755 "$SCRIPT_DIR/main.py" "$BIN_DIR/tailscale-autorunner"
echo "    [v] Executable berhasil dipasang."

# 2. Deteksi dan konfigurasi init system
echo "==> Mendeteksi Init System..."
INIT_SYSTEM="unknown"

if [ -d /run/systemd/system ] || (command -v systemctl >/dev/null 2>&1 && systemctl is-system-running >/dev/null 2>&1); then
  INIT_SYSTEM="systemd"
elif [ -d /run/openrc ] || command -v rc-service >/dev/null 2>&1 || [ -f /sbin/openrc-run ]; then
  INIT_SYSTEM="openrc"
elif [ -d /run/runit ] || [ -d /etc/sv ]; then
  INIT_SYSTEM="runit"
fi

case "$INIT_SYSTEM" in
  systemd)
    echo "    [v] Terdeteksi: systemd"
    echo "==> Mengonfigurasi service systemd..."
    sed "s|/usr/local/bin/tailscale-autorunner|$BIN_DIR/tailscale-autorunner|g" \
      "$SCRIPT_DIR/tailscale-autorunner.service" > /etc/systemd/system/tailscale-autorunner.service
    
    systemctl daemon-reload
    systemctl enable tailscale-autorunner.service

    if [ "$START_SERVICE" = true ]; then
      systemctl restart tailscale-autorunner.service
      echo "    [v] Service tailscale-autorunner aktif dan berjalan."
      echo "--- Status Service ---"
      systemctl status tailscale-autorunner.service --no-pager || true
    fi
    ;;

  openrc)
    echo "    [v] Terdeteksi: OpenRC"
    echo "==> Mengonfigurasi service OpenRC..."
    mkdir -p /etc/init.d
    sed "s|/usr/local/bin/tailscale-autorunner|$BIN_DIR/tailscale-autorunner|g" \
      "$SCRIPT_DIR/init/openrc/tailscale-autorunner" > /etc/init.d/tailscale-autorunner
    chmod 755 /etc/init.d/tailscale-autorunner

    rc-update add tailscale-autorunner default || true

    if [ "$START_SERVICE" = true ]; then
      rc-service tailscale-autorunner restart || true
      echo "    [v] Service OpenRC tailscale-autorunner telah dimulai."
    fi
    ;;

  runit)
    echo "    [v] Terdeteksi: runit"
    echo "==> Mengonfigurasi service runit..."
    mkdir -p /etc/sv/tailscale-autorunner
    sed "s|/usr/local/bin/tailscale-autorunner|$BIN_DIR/tailscale-autorunner|g" \
      "$SCRIPT_DIR/init/runit/run" > /etc/sv/tailscale-autorunner/run
    chmod 755 /etc/sv/tailscale-autorunner/run

    if [ -d /var/service ] && [ ! -e /var/service/tailscale-autorunner ]; then
      ln -s /etc/sv/tailscale-autorunner /var/service/
    fi
    echo "    [v] Service runit berhasil dikonfigurasi."
    ;;

  *)
    echo "    [!] Tidak terdeteksi init system standar (systemd/OpenRC/runit)."
    echo "        Binary telah terpasang di: $BIN_DIR/tailscale-autorunner"
    echo "        Anda dapat menjalankannya melalui metode berikut:"
    echo "        1. Daemon latar belakang:"
    echo "           nohup $BIN_DIR/tailscale-autorunner > /var/log/tailscale-autorunner.log 2>&1 &"
    echo "        2. Periodik melalui Cron (OpenWrt / Minimal Distro):"
    echo "           * * * * * $BIN_DIR/tailscale-autorunner --once"
    ;;
esac

echo ""
echo "[OK] Instalasi selesai!"
echo "     Perintah manual tersedia di terminal: tailscale-autorunner"

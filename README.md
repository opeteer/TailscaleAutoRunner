# Tailscale AutoRunner 🚀

![Python 3.x](https://img.shields.io/badge/Python-3.x-blue.svg)
![Platform: Linux](https://img.shields.io/badge/Platform-Linux-lightgrey.svg)
![Systemd](https://img.shields.io/badge/Service-Systemd-brightgreen.svg)

**Tailscale AutoRunner** is a lightweight, reliable background daemon designed for Linux systems to continuously monitor and maintain your [Tailscale](https://tailscale.com/) network connection. 

If your Tailscale connection unexpectedly drops, logs out, or stops, this service instantly detects the anomaly and automatically brings the interface back up (`tailscale up`), ensuring maximum uptime and zero manual intervention.

---

## ✨ Features

- **Automated Monitoring:** Periodically checks your Tailscale status via robust JSON output parsing.
- **Self-Healing:** Automatically runs `tailscale up` when the connection is dropped, stopped, or requires login.
- **Systemd Integration:** Seamlessly integrated as a Linux background service (daemon) for auto-start on boot.
- **Resource Efficient:** Minimal footprint using standard Python libraries with no external dependencies required.
- **Event Logging:** Records all state changes and reconnections securely into the systemd journal.

---

## 📋 Prerequisites

Before installing Tailscale AutoRunner, ensure your system meets the following requirements:

- **OS:** Any Systemd-based Linux distribution (Ubuntu, Debian, CentOS, Arch, etc.)
- **Tailscale:** Installed, configured, and authenticated at least once on the machine.
- **Python:** Python 3.x installed on the system.

---

## 🚀 Installation

Setting up Tailscale AutoRunner is straightforward. An installation script is provided to automatically configure the systemd daemon.

1. Navigate to the project directory:
   ```bash
   cd /home/opeteer/TailscaleAutoRunner
   ```
2. Run the installation script with `sudo` (root privileges are required to configure systemd):
   ```bash
   sudo ./install.sh
   ```

The script will automatically register `tailscale-autorunner.service`, start it, and enable it on boot!

---

## ⚙️ Configuration

By default, the daemon checks the Tailscale status every **30 seconds**. 

If you wish to change this interval:
1. Open `main.py` in your preferred text editor.
2. Locate the `CHECK_INTERVAL` variable and adjust it (in seconds):
   ```python
   CHECK_INTERVAL = 60  # e.g., Checks every 1 minute
   ```
3. Restart the service to apply the changes:
   ```bash
   sudo systemctl restart tailscale-autorunner.service
   ```

---

## 🔍 Monitoring & Logs

Because Tailscale AutoRunner runs natively as a systemd service, you can leverage standard `journalctl` commands to monitor its activity.

**View real-time logs:**
```bash
sudo journalctl -u tailscale-autorunner -f
```

**Check service status:**
```bash
sudo systemctl status tailscale-autorunner.service
```

---

## 🛑 Stopping & Uninstalling

To manually stop the auto-runner service temporarily:
```bash
sudo systemctl stop tailscale-autorunner.service
```

To fully disable it from starting on boot:
```bash
sudo systemctl disable tailscale-autorunner.service
```

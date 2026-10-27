# Tailscale AutoRunner 🚀

![Python 3.x](https://img.shields.io/badge/Python-3.x-blue.svg)
![Platform: Linux](https://img.shields.io/badge/Platform-Linux-lightgrey.svg)
![Init: systemd | OpenRC | runit](https://img.shields.io/badge/Init-systemd%20%7C%20OpenRC%20%7C%20runit-brightgreen.svg)

**Tailscale AutoRunner** is a portable, lightweight, and reliable background daemon designed for Linux systems to continuously monitor and maintain your [Tailscale](https://tailscale.com/) network connection.

If your Tailscale connection unexpectedly drops, logs out, or stops, this service instantly detects the anomaly and automatically brings the interface back up (`tailscale up`), ensuring maximum uptime and zero manual intervention.

---

## ✨ Features

- **🌐 Cross-Distro Portability:** Works out-of-the-box on major Linux distributions with automatic detection of your init system (**systemd**, **OpenRC**, **runit**, or standalone/cron).
- **🔄 Self-Healing Connection:** Automatically executes `tailscale up` whenever the daemon status becomes `Stopped` or `NeedsLogin`.
- **⚡ Zero External Dependencies:** Built using Python 3 standard libraries only (`subprocess`, `json`, `shutil`, `signal`, `logging`, `argparse`).
- **⏱️ Flexible Execution Modes:** Run as a continuous background service or use `--once` for periodic cron jobs (ideal for embedded or low-memory systems like OpenWrt).
- **🛡️ Graceful Handling:** Safe shutdown signal handling (`SIGTERM`/`SIGINT`), command timeouts, and dynamic binary detection (`/usr/bin`, `/snap/bin`, `/usr/local/bin`, etc.).

---

## 📋 Prerequisites

- **OS:** Any Linux distribution (Debian/Ubuntu, RHEL/Fedora/CentOS, Arch Linux, Alpine Linux, Void Linux, OpenWrt, etc.).
- **Python:** Python 3.6+ installed.
- **Tailscale:** Installed and authenticated at least once on the machine.

---

## 🚀 Installation

Tailscale AutoRunner includes an automated installer that detects your Linux environment and configures the appropriate service daemon.

1. Clone or download the repository:
   ```bash
   git clone https://github.com/your-username/TailscaleAutoRunner.git
   cd TailscaleAutoRunner
   ```

2. Run the installation script with root privileges:
   ```bash
   sudo ./install.sh
   ```

The installer will:
1. Verify Python 3 and Tailscale availability.
2. Install the binary to `/usr/local/bin/tailscale-autorunner`.
3. Detect your active init system (**systemd**, **OpenRC**, or **runit**) and install the corresponding service configuration.
4. Enable and start the service automatically.

### Custom Installation Options
```bash
# Specify a custom binary directory
sudo ./install.sh --bin-dir=/usr/bin

# Install without immediately starting the service
sudo ./install.sh --no-start
```

---

## 💻 Manual & Standalone Usage

Once installed, `tailscale-autorunner` is available directly in your terminal:

```bash
# Run with default 30-second interval
tailscale-autorunner

# Custom check interval (e.g., 60 seconds)
tailscale-autorunner --interval 60

# Verbose debug output
tailscale-autorunner -v

# Single check & exit (perfect for cron jobs)
tailscale-autorunner --once
```

### Running with Cron (for lightweight / non-daemon systems)
If running on systems without a traditional init daemon (such as routers or Docker containers), add a cron entry:
```cron
# Check every 2 minutes
*/2 * * * * /usr/local/bin/tailscale-autorunner --once > /dev/null 2>&1
```

---

## ⚙️ Configuration & Environment Variables

You can configure Tailscale AutoRunner via CLI flags or environment variables:

| Parameter | Environment Variable | Default | Description |
| :--- | :--- | :--- | :--- |
| `-i, --interval` | `CHECK_INTERVAL` | `30` | Time interval between status checks (seconds) |
| `--timeout` | `CMD_TIMEOUT` | `15` | Timeout for tailscale status commands (seconds) |
| `--tailscale-bin`| `TAILSCALE_BIN` | Auto | Custom path to the `tailscale` CLI binary |
| `--once` | - | `false` | Run single check and exit immediately |
| `-v, --verbose` | - | `false` | Enable detailed debug logging |

---

## 🔍 Monitoring & Logs

### systemd
```bash
# Real-time service logs
sudo journalctl -u tailscale-autorunner -f

# Service status
sudo systemctl status tailscale-autorunner.service
```

### OpenRC (Alpine / Gentoo)
```bash
sudo rc-service tailscale-autorunner status
```

---

## 🛑 Stopping & Uninstalling

To uninstall and remove all installed service files and binaries:

```bash
sudo ./uninstall.sh
```

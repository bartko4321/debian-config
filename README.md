# 🚀 Debian Post-Install Configuration Script

A comprehensive, automated configuration script (`install.sh`) designed for Debian systems after a fresh installation. It transforms a bare-bones system into an optimized, modern environment fully ready for work and entertainment.

> ⚠️ **NOTE:** At the very end, the script automatically reboots the system (`reboot`) to properly apply all changes made (including kernel, GPU driver, and GRUB configuration).

---

## ✨ Main Features

The `install.sh` script automates dozens of tasks divided into logical and safe stages:

### 1. Environment Preparation & Bloatware Removal
* **Removing unnecessary packages:** Gets rid of default, unused software (e.g. `konqueror`, `kmail`, `akonadi-server`, `nano`) to slim down the system.
* **BleachBit configuration:** Automatically deploys pre-prepared cleanup rules for the `root` user.
* **System shortcuts:** Adds a dedicated "System Maintenance" launcher to the user's application menu.

### 2. Automatic APT Repository Configuration
* **Modern sources:** Enables the `contrib`, `non-free`, and `non-free-firmware` components for both the classic `sources.list` format and the new DEB822 format (`debian.sources`).
* **i386 architecture:** Adds 32-bit package support, essential for games and Windows applications running through Wine.
* **Debian Backports:** Automatically configures the official backports repository matched to the current system codename.
* **External repositories:** Safely adds official GPG keys and sources for **Google Chrome** and **Brave Browser**.

### 3. GPU, Wi-Fi Drivers & Wine
* **Automatic GPU detection:** Identifies the graphics card (NVIDIA, AMD, or Intel) and installs optimal drivers, 32-bit libraries, and adds the appropriate kernel modules to `initramfs`.
* **Wi-Fi firmware:** Automatically installs kernel headers and missing proprietary firmware for wireless cards (including Broadcom, Intel).
* **Wine & Winetricks:** Installs the full Wine environment with the necessary audio/video libraries and downloads the latest version of `winetricks`.

### 4. Virtualization, Networking & Security
* **KVM / QEMU:** Installs the complete virtualization stack including `virt-manager` and automatically assigns the user to the required system groups.
* **Firewall (UFW):** Activates the firewall with a secure default configuration and rules allowing seamless virtual machine communication (`virbr0`).
* **Fast & secure DNS:** Assigns modern Cloudflare DNS servers (`1.1.1.1` / `1.0.0.1` along with IPv6 equivalents) to the active network connection.

### 5. Software (APT, Flatpak, .DEB)
* **Rich toolset:** Installs utility and developer packages (including `fastfetch`, `vulkan-tools`, `mangohud`, `gamemode`, `qbittorrent`, `telegram-desktop`, `kdenlive`, `7zip`, `rsync`).
* **Flatpak & Flathub:** Enables native Flatpak support and adds the **Flathub** repository.
* **Automatic installs from GitHub:** Downloads and installs the latest `.deb` releases for external applications: Discord, ls-fg, ls-fg-vk, and Faugus Launcher.

### 6. Appearance & Advanced Terminal Shell (ZSH)
* **Bootloader optimization:** Reduces the GRUB menu wait time to 0 seconds and enables the aesthetic Plymouth boot splash (`bgrt`).
* **Modern Terminal:** Switches the default user shell to `ZSH`, installs the **Oh My Zsh** framework, the **Powerlevel10k** theme, and configures automatic `fastfetch` summary display on every terminal launch.

---

## 🛠️ Prerequisites

The script runs processes that copy local configuration files. Before launching it, make sure the following are present in the same directory as `install.sh`:
* `.update.sh` – Your auxiliary update script.
* `Konserwacja systemu.desktop` – The application shortcut file.
* `bleachbit/` directory – Containing configuration files for the BleachBit tool.

---
### Adding a user to the sudo group:
```bash
sudo usermod -aG sudo $USER
```
## 🚀 How to Run

# 1. Clone your repository
```bash
git clone https://github.com/syscore88/debian-config.git
```

# 2. Enter the downloaded folder
```bash
cd debian-config
```

# 3. Make the install.sh script executable
```bash
chmod +x install.sh
```

# 4. Run the script as a regular user
```bash
./install.sh
```

---

### ☕ Support the Project

If you find this tool helpful and it saved you some time, consider buying me a coffee to support further development! 

[![Buy Me A Coffee](https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png)](https://buymeacoffee.com/bartekszczecinski)

---

## 🛡️ Security & Stability
* **`set -euo pipefail`:** The script immediately stops if any step returns an error, preventing inconsistencies in the system configuration.
* **APT lock handling:** Thanks to the `wait_for_apt` function, the script won't fail if the system is running automatic update checks in the background.
* **Safe sudo privilege:** The script temporarily grants the user a `NOPASSWD` privilege for package installation so the process isn't interrupted during a long absence. This entry is **unconditionally removed** at the end of the script, before the system restarts.

If you find this project useful, leave a star! ⭐

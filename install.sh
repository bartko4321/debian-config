#!/bin/bash
# ==========================================================
# KOMPLEKSOWY SKRYPT KONFIGURACYJNY SYSTEMU (DEBIAN 13)
# ==========================================================

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# --- Wykrywanie języka systemu ---
# Jeśli system jest ustawiony na polski (pl_PL/pl_*) -> komunikaty PL,
# w każdym innym przypadku -> komunikaty EN.
detect_system_lang() {
    local sys_lang="${LANG:-}"
    [[ -z "$sys_lang" ]] && sys_lang="${LC_ALL:-${LC_MESSAGES:-}}"
    if [[ "$sys_lang" == pl_PL* || "$sys_lang" == pl* ]]; then
        echo "pl"
    else
        echo "en"
    fi
}
SCRIPT_LANG="$(detect_system_lang)"

# --- Kolory i logowanie ---
INFO='\033[0;34m'
SUCCESS='\033[0;32m'
ERROR='\033[0;31m'
WARN='\033[0;33m'
NC='\033[0m'

# --- System logowania ---
# Zasada: na ekranie widoczne są TYLKO ważne komunikaty ogólne
# (log_info / log_ok / log_err). Wszystko inne (log_warn – szczegóły,
# pominięcia, drobne problemy) trafia WYŁĄCZNIE do pliku logu.
# Plik logu jest tworzony na stałe tylko wtedy, gdy wystąpi błąd
# (skrypt zakończy się kodem innym niż 0) – w przeciwnym razie
# tymczasowy log jest po prostu kasowany na końcu.
TMP_LOG="$(mktemp /tmp/install-log.XXXXXX)"
LOG_FILE="$HOME/install_error_$(date +%Y%m%d_%H%M%S).log"

# fd 3 = prawdziwy terminal (do wyświetlania ważnych komunikatów),
# fd 1/2 od teraz lądują wyłącznie w pliku tymczasowym (ukryte).
exec 3>&1
exec >>"$TMP_LOG" 2>&1

cleanup_on_exit() {
    local exit_code=$?
    if [ "$exit_code" -ne 0 ]; then
        cp -f "$TMP_LOG" "$LOG_FILE" 2>/dev/null || true
        if [[ "$SCRIPT_LANG" == "pl" ]]; then
            echo -e "${ERROR}✖ Wystąpił błąd (kod: $exit_code). Szczegółowy log zapisano w: $LOG_FILE${NC}" >&3
        else
            echo -e "${ERROR}✖ An error occurred (code: $exit_code). Detailed log saved to: $LOG_FILE${NC}" >&3
        fi
    fi
    rm -f "$TMP_LOG"
}
trap cleanup_on_exit EXIT

# --- Pomocnicze funkcje logowania ---
# Każda funkcja przyjmuje: "$1" = tekst PL, "$2" = tekst EN
_pick_msg() { [[ "$SCRIPT_LANG" == "pl" ]] && echo "$1" || echo "$2"; }

log_info() { local m; m="$(_pick_msg "$1" "$2")"; echo -e "${INFO}==> $m${NC}" >&3; echo -e "${INFO}==> $m${NC}"; }
log_ok()   { local m; m="$(_pick_msg "$1" "$2")"; echo -e "${SUCCESS}✔ $m${NC}" >&3; echo -e "${SUCCESS}✔ $m${NC}"; }
log_err() {
    local m prefix
    m="$(_pick_msg "$1" "$2")"
    prefix="$([[ "$SCRIPT_LANG" == "pl" ]] && echo "BŁĄD" || echo "ERROR")"
    echo -e "${ERROR}✖ ${prefix}: $m${NC}" >&3
    echo -e "${ERROR}✖ ${prefix}: $m${NC}"
}
# log_warn: celowo NIE trafia na ekran (fd 3) - tylko do logu w tle
log_warn() {
    local m prefix
    m="$(_pick_msg "$1" "$2")"
    prefix="$([[ "$SCRIPT_LANG" == "pl" ]] && echo "UWAGA" || echo "WARNING")"
    echo -e "${WARN}⚠ ${prefix}: $m${NC}"
}

trap 'log_err "Błąd w linii $LINENO. Polecenie: $BASH_COMMAND" "Error at line $LINENO. Command: $BASH_COMMAND"' ERR

# --- Zmienna lokalizująca folder ze skryptem (niezależnie skąd jest uruchamiany) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# --- Funkcja zapobiegająca blokadom APT ---
wait_for_apt() {
    sudo systemctl stop packagekit 2>/dev/null || true

    while sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || \
          sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
          sudo killall -0 apt apt-get dpkg 2>/dev/null; do
        sleep 3
    done
}

# --- Zmienne globalne ---
CURRENT_USER=$(whoami)
DEB_DIR="/tmp/debs_$$"

log_info "Ten skrypt jest dostosowany do Debian 13 (Stable). Rozpoczynam konfigurację..." \
         "This script is tailored for Debian 13 (Stable). Starting configuration..."

# --- Sprawdzenie uprawnień ---
if [[ "$EUID" -eq 0 ]]; then
    log_err "Nie uruchamiaj skryptu jako root. Użyj zwykłego użytkownika z dostępem do sudo." \
            "Do not run this script as root. Use a regular user with sudo access."
    exit 1
fi

# ── Tymczasowy wyjątek sudo dla apt-get ───────────────────────
sudo -v
echo "$CURRENT_USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/99-temp-installer > /dev/null

# ==========================================================
# 1. PRZYGOTOWANIE
# ==========================================================
log_info "Przygotowanie konfiguracji użytkownika..." \
         "Preparing user configuration..."

# Kopiowanie skryptu aktualizacji (jeśli istnieje)
if [[ -f "$SCRIPT_DIR/.update.sh" ]]; then
    cp -af "$SCRIPT_DIR/.update.sh" ~/.update.sh
    chmod +x ~/.update.sh
fi

# ── Kopiowanie .local i .config do katalogu domowego ──────────
if [[ -d "$SCRIPT_DIR/.local" ]]; then
    mkdir -p ~/.local
    cp -afT "$SCRIPT_DIR/.local" ~/.local
    log_ok "Skopiowano katalog '.local' do \$HOME" \
           "Copied '.local' directory to \$HOME"
else
    log_warn "Brak katalogu '.local' w katalogu skryptu – pominięto" \
             "No '.local' directory in script folder – skipped"
fi

if [[ -d "$SCRIPT_DIR/.config" ]]; then
    mkdir -p ~/.config
    cp -afT "$SCRIPT_DIR/.config" ~/.config
    log_ok "Skopiowano katalog '.config' do \$HOME" \
           "Copied '.config' directory to \$HOME"
else
    log_warn "Brak katalogu '.config' w katalogu skryptu – pominięto" \
             "No '.config' directory in script folder – skipped"
fi

# ==========================================================
# 2. REPOZYTORIA I AKTUALIZACJA SYSTEMU
# ==========================================================
log_info "Konfiguracja repozytoriów APT..." \
         "Configuring APT repositories..."

wait_for_apt

# Wykomentuj wpisy cdrom
sudo sed -i '/cdrom/s/^/#/' /etc/apt/sources.list 2>/dev/null || true

# Dodaj architektury
sudo dpkg --add-architecture i386

# Rozszerzenie repozytoriów o contrib, non-free, non-free-firmware (stary format)
if [[ -f /etc/apt/sources.list ]]; then
    if ! grep -q "non-free-firmware" /etc/apt/sources.list; then
        sudo sed -i -E 's/ main($| )/ main contrib non-free non-free-firmware\1/' /etc/apt/sources.list || true
    fi
fi

# Rozszerzenie repozytoriów dla Debiana 12/13+ (nowy format DEB822)
if [[ -f /etc/apt/sources.list.d/debian.sources ]]; then
    if ! grep -q "non-free-firmware" /etc/apt/sources.list.d/debian.sources; then
        sudo sed -i -E '/^Components:/ s/$/ contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources || true
    fi
fi

# Narzędzia potrzebne do konfiguracji kluczy GPG i wykrywania GPU
wait_for_apt
sudo apt-get update -yq
sudo apt-get install -yq curl wget gnupg pciutils

# Utworzenie zalecanego katalogu na klucze (Debian 12+) i wymuszenie dostępu (755)
sudo mkdir -p /etc/apt/keyrings
sudo chmod 755 /etc/apt/keyrings

# Repozytorium Google Chrome
if [ ! -f /etc/apt/keyrings/google-chrome.gpg ]; then
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
        | sudo gpg --dearmor --yes -o /etc/apt/keyrings/google-chrome.gpg
    sudo chmod 644 /etc/apt/keyrings/google-chrome.gpg
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] \
http://dl.google.com/linux/chrome/deb/ stable main" \
        | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null
fi

# Repozytorium Brave (Origin)
sudo mkdir -p /usr/share/keyrings
sudo rm -f /usr/share/keyrings/brave-browser-archive-keyring.gpg
BRAVE_KEY_ID="0686B78420038257"
BRAVE_GNUPGHOME="$(mktemp -d)"
if ! gpg --homedir "$BRAVE_GNUPGHOME" --keyserver hkps://keyserver.ubuntu.com --recv-keys "$BRAVE_KEY_ID"; then
    log_warn "keyserver.ubuntu.com nie odpowiedział, próbuję keys.openpgp.org..." \
             "keyserver.ubuntu.com did not respond, trying keys.openpgp.org..."

    if ! gpg --homedir "$BRAVE_GNUPGHOME" --keyserver hkps://keys.openpgp.org --recv-keys "$BRAVE_KEY_ID"; then
        log_warn "Nie udało się pobrać klucza Brave z żadnego serwera." \
                 "Failed to fetch Brave GPG key from any server."
    fi
fi
gpg --homedir "$BRAVE_GNUPGHOME" --export "$BRAVE_KEY_ID" \
    | sudo tee /usr/share/keyrings/brave-browser-archive-keyring.gpg > /dev/null
rm -rf "$BRAVE_GNUPGHOME"
sudo chmod 644 /usr/share/keyrings/brave-browser-archive-keyring.gpg
sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources \
    https://brave-browser-apt-release.s3.brave.com/brave-browser.sources

wait_for_apt
sudo apt-get update -yq && sudo apt-get full-upgrade -yq

# ==========================================================
# 3. INSTALACJA PAKIETÓW
# ==========================================================
log_info "Instalacja podstawowych narzędzi i firmware..." \
         "Installing basic tools and firmware..."

wait_for_apt
sudo apt-get install -yq isenkram-cli firmware-linux firmware-linux-nonfree \
    || log_warn "Błąd instalacji pakietów firmware." "Error installing firmware packages."

sudo isenkram-autoinstall-firmware \
    || log_warn "isenkram-autoinstall-firmware zakończył się błędem (ignoruję)" \
               "isenkram-autoinstall-firmware failed (ignoring)"

# --- Usuwanie zbędnych pakietów ---
log_info "Usuwanie zbędnych pakietów..." \
         "Removing unnecessary packages..."
PACKAGES_REMOVE=(
    nano konqueror plasma-browser-integration plasma-vault krdp krfb 
    plasma-thunderbolt kontact kmail kontrast plasma-welcome imagemagick 
    kaddressbook kdepim-runtime akonadi-server akregator korganizer 
    epiphany decibels rhythmbox showtime cosmic-player parole
    kwalletmanager
)
for pkg in "${PACKAGES_REMOVE[@]}"; do
    sudo apt-get purge -yq "$pkg" 2>/dev/null || true
done
sudo apt-get autoremove -yq

# Czyszczenie pozostałości po pakietach KDE PIM
log_info "Czyszczenie pozostałości po Akonadi/KMail/Kontact w katalogu domowym..." \
         "Cleaning up leftover Akonadi/KMail/Kontact files in the home directory..."
rm -rf ~/.local/share/akonadi ~/.local/share/kmail2 ~/.local/share/local-mail \
       ~/.local/share/contacts ~/.local/share/korganizer ~/.local/share/akregator \
       ~/.local/share/kontact ~/.local/share/konqueror
rm -rf ~/.config/akonadi* ~/.config/kmail* ~/.config/kontact* \
       ~/.config/korganizer* ~/.config/kaddressbook* ~/.config/akregator* \
       ~/.config/emailidentities ~/.config/mailtransports

# --- Wyłączenie KDE Wallet (Portfela) ---
mkdir -p ~/.config
if [[ -f ~/.config/kwalletrc ]]; then
    if grep -q "^\[Wallet\]" ~/.config/kwalletrc; then
        sed -i '/^\[Wallet\]/,/^\[/{s/^Enabled=.*/Enabled=false/}' ~/.config/kwalletrc
        grep -q "^Enabled=" ~/.config/kwalletrc || sed -i '/^\[Wallet\]/a Enabled=false' ~/.config/kwalletrc
    else
        printf '[Wallet]\nEnabled=false\n' >> ~/.config/kwalletrc
    fi
else
    printf '[Wallet]\nEnabled=false\n' > ~/.config/kwalletrc
fi

# --- Główna instalacja ---
log_info "Instalacja pakietów głównych..." \
         "Installing main packages..."
wait_for_apt
PACKAGES_INSTALL=(
    # Przeglądarki komunikatory
    google-chrome-stable brave-origin thunderbird telegram-desktop thunderbird-l10n-pl
    # Multimedia
    qbittorrent krita audacity gmic mixxx kdenlive handbrake soundconverter vlc elisa
    # Narzędzia systemowe
    vim dconf-editor hunspell-pl fastfetch bleachbit profile-sync-daemon
    plymouth plymouth-themes
    unrar-free mc btrfs-progs exfatprogs ntfs-3g os-prober
    adb fastboot fsarchiver inxi pv rsync cdemu-daemon cdemu-client
    7zip makeself zenity innoextract needrestart flatpak timeshift
    # Python
    python3-defusedxml python3-packaging python3-pip python3-tqdm
    # Gaming / GPU
    libayatana-appindicator3-1 gamemode vulkan-tools mangohud
    vkd3d-compiler goverlay
    # Kompilacja
    gcc make cmake meson ninja-build just build-essential git
    # GStreamer
    gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly
    # Inne
    zsh zsh-syntax-highlighting zsh-autosuggestions
)

FAILED_PACKAGES=()
for pkg in "${PACKAGES_INSTALL[@]}"; do
    sudo apt-get install -yq "$pkg" || FAILED_PACKAGES+=("$pkg")
done
if [[ ${#FAILED_PACKAGES[@]} -gt 0 ]]; then
    log_warn "Nie udało się zainstalować: ${FAILED_PACKAGES[*]}" \
             "Failed to install: ${FAILED_PACKAGES[*]}"
fi

# --- Winetricks ---
sudo apt-get install -yq cabextract unzip wget >/dev/null 2>&1 || true
if sudo curl -fsSLo /usr/local/bin/winetricks \
        https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
     && sudo chmod +x /usr/local/bin/winetricks; then
     :
elif sudo apt-get install -yq winetricks; then
     :
else
    log_warn "Nie udało się zainstalować winetricks — pomijam." \
             "Failed to install winetricks — skipping."
fi

# --- WINE ORAZ 32-BITOWE BIBLIOTEKI DO GIER ---
log_info "Instalacja Wine oraz 32-bitowych bibliotek (Audio, MangoHud)..." \
         "Installing Wine and 32-bit libraries (Audio, MangoHud)..."
wait_for_apt
sudo apt-get install -yq libpulse0:i386 libopenal1:i386 mangohud:i386

if sudo apt-get install -yq wine wine64 wine32:i386; then
   :

else
    log_warn "Wystąpił problem z pakietem wine w systemie. Próba instalacji z repozytorium WineHQ..." \
             "There was a problem with the system wine package. Trying to install from the WineHQ repository..."
    sudo mkdir -pm755 /etc/apt/keyrings
    if ! sudo curl -fsSLo /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key \
        || ! sudo curl -fsSLo /etc/apt/sources.list.d/winehq.sources \
            https://dl.winehq.org/wine-builds/debian/dists/trixie/winehq-trixie.sources; then
        log_err "Nie udało się pobrać klucza lub repozytorium WineHQ." \
                "Failed to download WineHQ key or repository."
    else
        wait_for_apt
        sudo apt-get update -yq
        if sudo apt-get install -yq --install-recommends winehq-stable; then
            log_ok "Wine zainstalowany z repozytorium WineHQ." \
                   "Wine installed from the WineHQ repository."
        else
            log_err "Nie udało się zainstalować Wine ze źródła zapasowego." \
                    "Failed to install Wine from the fallback source."
        fi
    fi

# ==========================================================
# WYKRYWANIE GPU: 32-BITOWE BIBLIOTEKI I MODUŁY INITRAMFS
# ==========================================================
log_info "Wykrywanie układu graficznego (biblioteki 32-bit oraz moduły jądra)..." \
         "Detecting the graphics chip (32-bit libraries and kernel modules)..."
VGA_INFO=$(lspci -nn | grep -iE "VGA|3D|Display" || true)
MODULES_FILE="/etc/initramfs-tools/modules"

add_module() {
    grep -q "^$1" "$MODULES_FILE" || echo "$1" | sudo tee -a "$MODULES_FILE" > /dev/null
}

wait_for_apt
if echo "$VGA_INFO" | grep -iq "NVIDIA"; then
    log_ok "Wykryto układ NVIDIA. Instaluję biblioteki i dodaję moduł..." \
           "Detected an NVIDIA chip. Installing libraries and adding module..."
    sudo apt-get install -yq libgl1-nvidia-glvnd-glx:i386
    add_module "nvidia"
    add_module "nvidia_modeset"
    add_module "nvidia_uvm"
    add_module "nvidia_drm"
elif echo "$VGA_INFO" | grep -iq "AMD"; then
    log_ok "Wykryto układ AMD. Instaluję biblioteki Mesa i dodaję moduł amdgpu..." \
           "Detected an AMD chip. Installing Mesa libraries and adding the amdgpu module..."
    sudo apt-get install -yq libgl1-mesa-dri:i386 mesa-vulkan-drivers:i386
    add_module "amdgpu"
elif echo "$VGA_INFO" | grep -iq "Intel"; then
    log_ok "Wykryto układ Intel. Instaluję biblioteki Mesa i dodaję moduł i915..." \
           "Detected an Intel chip. Installing Mesa libraries and adding the i915 module..."
    sudo apt-get install -yq libgl1-mesa-dri:i386 mesa-vulkan-drivers:i386
    add_module "i915"
else
    log_warn "Nie rozpoznano jednoznacznie układu. Instaluję domyślne pakiety Mesa." \
             "Could not unambiguously identify the GPU. Installing default Mesa packages."
    sudo apt-get install -yq libgl1-mesa-dri:i386 mesa-vulkan-drivers:i386
fi

log_info "Przebudowa obrazu initramfs..." \
         "Rebuilding the initramfs image..."
sudo update-initramfs -u

# --- Repozytorium Flathub ---
log_info "Dodawanie repozytorium Flathub..." \
         "Adding the Flathub repository..."
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true

log_info "Odświeżanie metadanych Flathub..." \
         "Refreshing Flathub metadata..."
sudo flatpak update --appstream || true

# --- Gear Lever i Flatseal (Flathub) ---
sudo flatpak install -y flathub com.github.tchx84.Flatseal \
    || log_warn "Błąd instalacji Flatseal" "Error installing Flatseal"

sudo flatpak install -y flathub it.mijorus.gearlever \
    || log_warn "Błąd instalacji Gear Lever" "Error installing Gear Lever"

# --- Paczki .deb z internetu ---
log_info "Pobieranie i instalacja paczek .deb..." \
         "Downloading and installing .deb packages..."
mkdir -p "$DEB_DIR"

download_deb() {
    local name="$1" url="$2" dest="$3"
    if ! wget -q --timeout=30 -O "$dest" "$url"; then
        log_warn "Nie udało się pobrać: $name ($url) — pomijam" \
                 "Failed to download: $name ($url) — skipping"
        rm -f "$dest"
    fi
}

get_github_deb_url() {
    local repo="$1" pattern="$2"
    curl -sf "https://api.github.com/repos/${repo}/releases/latest" \
        | grep "browser_download_url.*${pattern}" \
        | cut -d '"' -f 4 \
        || true
}

download_deb "Discord" \
    "https://discord.com/api/download?platform=linux&format=deb" \
    "$DEB_DIR/discord.deb"

LSFG_URL=$(get_github_deb_url "YuriSizov/ls-fg"    "ls-fg_.*deb")
LSFG_VK_URL=$(get_github_deb_url "YuriSizov/ls-fg-vk" "deb")
FAUGUS_URL=$(get_github_deb_url "faugus/faugus-launcher" "deb")

if [[ -n "$LSFG_URL" ]]; then download_deb "ls-fg" "$LSFG_URL" "$DEB_DIR/lsfg.deb"; fi
if [[ -n "$LSFG_VK_URL" ]]; then download_deb "ls-fg-vk" "$LSFG_VK_URL" "$DEB_DIR/lsfg-vk.deb"; fi
if [[ -n "$FAUGUS_URL" ]]; then download_deb "Faugus Launcher" "$FAUGUS_URL" "$DEB_DIR/faugus.deb"; fi

shopt -s nullglob
DEB_FILES=("$DEB_DIR"/*.deb)
if [[ ${#DEB_FILES[@]} -gt 0 ]]; then
    wait_for_apt
    sudo apt-get install -yq "${DEB_FILES[@]}"
else
    log_warn "Brak plików .deb do zainstalowania" "No .deb files to install"
fi
shopt -u nullglob
rm -rf "$DEB_DIR"

# ==========================================================
# 4. WIRTUALIZACJA I FIREWALL
# ==========================================================
log_info "Konfiguracja wirtualizacji i UFW..." \
         "Configuring virtualization and UFW..."

wait_for_apt
sudo apt-get install -yq \
    virt-manager qemu-system qemu-utils \
    libvirt-daemon-system libvirt-clients \
    ovmf dnsmasq \
    bluetooth bluez bluez-firmware bluez-tools ufw

for svc in libvirtd virtqemud; do
    if systemctl list-unit-files "${svc}.service" 2>/dev/null | grep -q "$svc"; then
        sudo systemctl enable --now "${svc}.service"
        log_ok "Uruchomiono serwis: $svc" "Started service: $svc"
        break
    fi
done

if ! sudo virsh net-info default &>/dev/null; then
    log_warn "Sieć 'default' nie jest zdefiniowana - definiuję z domyślnego XML..." \
             "Network 'default' is not defined - defining it from the default XML..."
    sudo virsh net-define /usr/share/libvirt/networks/default.xml || true
fi
sudo virsh net-start default 2>/dev/null || true
sudo virsh net-autostart default || log_warn "Nie udało się ustawić autostartu sieci 'default'." \
                                            "Failed to enable autostart for network 'default'."

if command -v ufw &>/dev/null || [[ -x /usr/sbin/ufw ]]; then
    if [[ -f /etc/default/ufw ]]; then
        sudo sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' \
            /etc/default/ufw || true
    fi

    sudo ufw --force reset
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow in  on virbr0
    sudo ufw allow out on virbr0
    sudo ufw allow from 192.168.122.0/24
    sudo ufw --force enable
else
    log_warn "ufw niedostępny — pomijam konfigurację firewalla" \
             "ufw not available — skipping firewall configuration"
fi

for grp in libvirt libvirt-qemu kvm; do
    if getent group "$grp" &>/dev/null; then
        sudo usermod -aG "$grp" "$CURRENT_USER" \
            && log_ok "Dodano $CURRENT_USER do grupy $grp" "Added $CURRENT_USER to group $grp"
    fi
done

# ==========================================================
# 5. PLYMOUTH (EKRAN STARTOWY)
# ==========================================================
log_info "Konfiguracja Plymouth (bgrt)..." \
         "Configuring Plymouth (bgrt)..."

GRUB_PARAMS="quiet splash plymouth.ignore-serial-consoles"
if ! grep -q "plymouth.ignore-serial-consoles" /etc/default/grub; then
    sudo sed -i \
        "s|GRUB_CMDLINE_LINUX_DEFAULT=\"\(.*\)\"|GRUB_CMDLINE_LINUX_DEFAULT=\"\1 ${GRUB_PARAMS}\"|" \
        /etc/default/grub || true
fi

sudo plymouth-set-default-theme bgrt \
    || log_warn "plymouth-set-default-theme nie powiodło się (ignoruję)" \
               "plymouth-set-default-theme failed (ignoring)"
sudo update-grub
sudo update-initramfs -u \
    || log_warn "update-initramfs nie powiodło się (ignoruję)" \
               "update-initramfs failed (ignoring)"

# ==========================================================
# 6. FINALIZACJA I OPTYMALIZACJA
# ==========================================================
log_info "Finalizacja i optymalizacja..." \
         "Finalizing and optimizing..."

sudo systemctl enable fstrim.timer || true
sudo journalctl --vacuum-time=2d || true

sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub || true
sudo update-grub

if [[ -d "$SCRIPT_DIR/bleachbit" ]]; then
    sudo mkdir -p /root/.config/bleachbit
    sudo cp -af "$SCRIPT_DIR/bleachbit/." /root/.config/bleachbit/
fi

ACTIVE_CONN=$(nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null \
    | grep -v "^lo" | head -n 1 | cut -d: -f1 || true)
if [[ -n "$ACTIVE_CONN" ]]; then
    sudo nmcli connection modify "$ACTIVE_CONN" \
        ipv4.dns "1.1.1.1,1.0.0.1" \
        ipv6.dns "2606:4700:4700::1112,2606:4700:4700::1002"
    sudo nmcli connection up "$ACTIVE_CONN" || true
fi

# ==========================================================
# 7. ZSH + OH MY ZSH + POWERLEVEL10K
# ==========================================================
log_info "Konfiguracja ZSH..." "Configuring ZSH..."

if command -v zsh &>/dev/null; then
    sudo chsh -s /usr/bin/zsh "$CURRENT_USER"

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
            "" --unattended || true
    fi

    P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [[ ! -d "$P10K_DIR" ]]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR" || true
    fi

    ZSHRC="$HOME/.zshrc"
    if [[ -f "$ZSHRC" ]]; then
        sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$ZSHRC" || true
        sed -i 's/^plugins=(.*/plugins=(git sudo systemd debian)/' "$ZSHRC" || true
        grep -q "LC_ALL=pl_PL.UTF-8" "$ZSHRC" || echo "export LC_ALL=pl_PL.UTF-8" >> "$ZSHRC"
        grep -q "^fastfetch"         "$ZSHRC" || echo "fastfetch"                  >> "$ZSHRC"
        grep -q "zsh-syntax-highlighting.zsh" "$ZSHRC" || echo "source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> "$ZSHRC"
        grep -q "zsh-autosuggestions.zsh"     "$ZSHRC" || echo "source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh"         >> "$ZSHRC"
    fi
fi

# ==========================================================
log_info "Sprzątanie po instalacji..." "Cleaning up after installation..."
sudo rm -f /etc/sudoers.d/99-temp-installer

log_ok "KONFIGURACJA ZAKOŃCZONA SUKCESEM!" "CONFIGURATION COMPLETED SUCCESSFULLY!"
sleep 3
systemctl reboot

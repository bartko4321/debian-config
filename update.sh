#!/bin/bash

# Kolory / Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# =========================================================
# WYKRYWANIE JĘZYKA SYSTEMU / SYSTEM LANGUAGE DETECTION
# =========================================================
DETECTED_LOCALE="${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}"
if [ -z "$DETECTED_LOCALE" ] && command -v locale &> /dev/null; then
    DETECTED_LOCALE=$(locale 2>/dev/null | grep -m1 '^LANG=' | cut -d= -f2)
fi

if [[ "$DETECTED_LOCALE" == pl_PL* ]] || [[ "$DETECTED_LOCALE" == pl* ]]; then
    IS_PL=true
else
    IS_PL=false
fi

# =========================================================
# KOMUNIKATY / MESSAGES
# =========================================================
if [ "$IS_PL" = true ]; then
    MSG_TITLE="    KOMPLEKSOWY SKRYPT AKTUALIZACJI I CZYSZCZENIA    "
    MSG_ASK_PASS="Proszę podać hasło administratora (sudo):"
    MSG_FULL_UPDATE="==> Pełna aktualizacja systemu (APT)..."
    MSG_FLATPAK_UPDATE="==> Pełna aktualizacja aplikacji Flatpak..."
    MSG_FWUPD_REFRESH="==> Odświeżanie metadanych firmware (fwupd)..."
    MSG_FWUPD_UPDATE="==> Sprawdzanie i instalowanie aktualizacji firmware (fwupd)..."
    MSG_FWUPD_ABSENT="==> fwupdmgr nieobecny w systemie - pomijam aktualizację firmware."
    MSG_FWUPD_RESTART_NEEDED="UWAGA: Zainstalowano aktualizację firmware wymagającą restartu!"
    MSG_PHASE1_TITLE="--- FAZA 1: SYSTEM (SUDO) ---"
    MSG_AUTOREMOVE="==> Usuwanie osieroconych pakietów i zbędnych zależności..."
    MSG_DEBORPHAN="==> Usuwanie osieroconych bibliotek (deborphan)..."
    MSG_APTKEY_UPDATE="==> Aktualizacja bazy kluczy zaufanych..."
    MSG_AUTOCLEAN="==> Czyszczenie cache pobierania APT (stare pakiety)..."
    MSG_REMOVE_PPA_LISTS="==> Usuwanie nieużywanych repozytoriów (PPA/listy)..."
    MSG_FLATPAK_CLEAN_SYS="==> Kompleksowe czyszczenie Flatpak (System)..."
    MSG_FLATPAK_REMOVING_REMOTE="Usuwanie nieużywanego źródła Flatpak:"
    MSG_FLATPAK_CLEAN_VARAPP_SYS="==> Czyszczenie osieroconych danych po usuniętych aplikacjach w /var/app..."
    MSG_FLATPAK_REMOVING_VARAPP_SYS="Usuwanie osieroconych danych systemowych w /var/app:"
    MSG_FLATPAK_ABSENT_SYS="==> Flatpak nieobecny - pomijam czyszczenie systemowe."
    MSG_CLEAN_LOGS="==> Czyszczenie logów (Journalctl + /var/log)..."
    MSG_CLEAN_TMP="==> Czyszczenie starego /tmp i /var/tmp (starsze niż 3 dni)..."
    MSG_REMOVE_OLD_KERNELS="==> Usuwanie starych kerneli (Debian)..."
    MSG_REMOVING_KERNELS="Usuwanie:"
    MSG_ONLY_CURRENT_KERNEL="Tylko aktualny kernel w systemie."
    MSG_PHASE2_TITLE="--- FAZA 2: UŻYTKOWNIK (REAL USER) ---"
    MSG_CLEAN_USER_CACHE="==> Czyszczenie starego cache (omijanie przeglądarek)..."
    MSG_CLEAN_THUMBS="==> Czyszczenie starych miniatur..."
    MSG_FLATPAK_CLEAN_USER="==> Czyszczenie Flatpak (Użytkownik)..."
    MSG_FLATPAK_CLEAN_VARAPP_USER="==> Czyszczenie osieroconych danych po usuniętych aplikacjach w ~/.var/app..."
    MSG_FLATPAK_REMOVING_VARAPP_USER="Usuwanie osieroconych danych użytkownika w ~/.var/app:"
    MSG_REBUILD_FONTS="==> Odświeżanie cache czcionek..."
    MSG_CLEAN_VIRT="==> Czyszczenie virt-manager i reset dconf..."
    MSG_DCONF_DONE="==> dconf reset wykonany."
    MSG_DONE_TITLE="     AKTUALIZACJA I CZYSZCZENIE ZAKOŃCZONE!          "
    MSG_CHECK_SYSTEM="==> Sprawdzanie stanu systemu..."
    MSG_RESTART_WARN1="UWAGA: Zainstalowano nowy kernel lub ważne pakiety!"
    MSG_RESTART_WARN2=" ZALECANY JEST RESTART KOMPUTERA!                     "
    MSG_NO_RESTART_NEEDED="==> Restart systemu nie jest aktualnie wymagany."
    MSG_PRESS_ENTER="Naciśnij [ENTER], aby zakończyć..."
else
    MSG_TITLE="       COMPREHENSIVE UPDATE AND CLEANUP SCRIPT       "
    MSG_ASK_PASS="Please enter the administrator (sudo) password:"
    MSG_FULL_UPDATE="==> Performing a full system update (APT)..."
    MSG_FLATPAK_UPDATE="==> Updating Flatpak applications..."
    MSG_FWUPD_REFRESH="==> Refreshing firmware metadata (fwupd)..."
    MSG_FWUPD_UPDATE="==> Checking for and installing firmware updates (fwupd)..."
    MSG_FWUPD_ABSENT="==> fwupdmgr not present on the system - skipping firmware update."
    MSG_FWUPD_RESTART_NEEDED="WARNING: A firmware update requiring a restart was installed!"
    MSG_PHASE1_TITLE="--- PHASE 1: SYSTEM (SUDO) ---"
    MSG_AUTOREMOVE="==> Removing orphaned packages and unnecessary dependencies..."
    MSG_DEBORPHAN="==> Removing orphaned libraries (deborphan)..."
    MSG_APTKEY_UPDATE="==> Updating the trusted keys database..."
    MSG_AUTOCLEAN="==> Cleaning the APT download cache (old packages)..."
    MSG_REMOVE_PPA_LISTS="==> Removing unused repositories (PPA/lists)..."
    MSG_FLATPAK_CLEAN_SYS="==> Comprehensive Flatpak cleanup (System)..."
    MSG_FLATPAK_REMOVING_REMOTE="Removing unused Flatpak remote:"
    MSG_FLATPAK_CLEAN_VARAPP_SYS="==> Cleaning orphaned data from removed apps in /var/app..."
    MSG_FLATPAK_REMOVING_VARAPP_SYS="Removing orphaned system data in /var/app:"
    MSG_FLATPAK_ABSENT_SYS="==> Flatpak not present - skipping system cleanup."
    MSG_CLEAN_LOGS="==> Cleaning logs (Journalctl + /var/log)..."
    MSG_CLEAN_TMP="==> Cleaning old /tmp and /var/tmp (older than 3 days)..."
    MSG_REMOVE_OLD_KERNELS="==> Removing old kernels (Debian)..."
    MSG_REMOVING_KERNELS="Removing:"
    MSG_ONLY_CURRENT_KERNEL="Only the current kernel is installed on the system."
    MSG_PHASE2_TITLE="--- PHASE 2: USER (REAL USER) ---"
    MSG_CLEAN_USER_CACHE="==> Cleaning old cache (skipping browsers)..."
    MSG_CLEAN_THUMBS="==> Cleaning old thumbnails..."
    MSG_FLATPAK_CLEAN_USER="==> Cleaning Flatpak (User)..."
    MSG_FLATPAK_CLEAN_VARAPP_USER="==> Cleaning orphaned data from removed apps in ~/.var/app..."
    MSG_FLATPAK_REMOVING_VARAPP_USER="Removing orphaned user data in ~/.var/app:"
    MSG_REBUILD_FONTS="==> Refreshing font cache..."
    MSG_CLEAN_VIRT="==> Cleaning virt-manager and resetting dconf..."
    MSG_DCONF_DONE="==> dconf reset completed."
    MSG_DONE_TITLE="       UPDATE AND CLEANUP COMPLETE!                  "
    MSG_CHECK_SYSTEM="==> Checking system status..."
    MSG_RESTART_WARN1="WARNING: A new kernel or important packages have been installed!"
    MSG_RESTART_WARN2=" A SYSTEM RESTART IS RECOMMENDED!                     "
    MSG_NO_RESTART_NEEDED="==> A system restart is not currently required."
    MSG_PRESS_ENTER="Press [ENTER] to finish..."
fi

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}${MSG_TITLE}${NC}"
echo -e "${BLUE}=====================================================${NC}"

# 1. ZAPYTANIE O HASŁO TYLKO RAZ / ASK FOR PASSWORD ONCE
echo -e "${YELLOW}${MSG_ASK_PASS}${NC}"
sudo -v

# Podtrzymanie sudo / Keep sudo alive
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_KEEP_ALIVE_PID=$!

echo -e "\n${GREEN}${MSG_FULL_UPDATE}${NC}"

# Używamy apt-get (stabilne dla skryptów) + ukrywamy irytujące komunikaty o i386
# (apt-get zwraca komunikaty w języku systemu, więc filtrujemy oba warianty)
sudo apt-get update 2>&1 | grep -v "nie obsługuje architektury\|Pomijanie pozyskania skonfigurowanego pliku\|does not support architecture\|Skipping acquire of configured file"

# Kontynuacja pełnej aktualizacji (dist-upgrade to odpowiednik full-upgrade w apt-get)
sudo apt-get dist-upgrade -y

# Aktualizacja Flatpak / Flatpak update
if command -v flatpak &> /dev/null; then
    echo -e "\n${GREEN}${MSG_FLATPAK_UPDATE}${NC}"
    flatpak update -y
fi

# Aktualizacja firmware / Firmware update
FWUPD_RESTART_NEEDED=false
if command -v fwupdmgr &> /dev/null; then
    echo -e "\n${GREEN}${MSG_FWUPD_REFRESH}${NC}"
    sudo fwupdmgr refresh --force

    echo -e "\n${GREEN}${MSG_FWUPD_UPDATE}${NC}"
    FWUPD_OUT=$(sudo fwupdmgr update -y 2>&1)
    echo "$FWUPD_OUT"

    if echo "$FWUPD_OUT" | grep -qiE "restart|reboot"; then
        FWUPD_RESTART_NEEDED=true
    fi
else
    echo -e "\n${YELLOW}${MSG_FWUPD_ABSENT}${NC}"
fi

echo -e "\n${BLUE}${MSG_PHASE1_TITLE}${NC}"

echo -e "${GREEN}${MSG_AUTOREMOVE}${NC}"
sudo apt-get autoremove --purge -y

# Deborphan
if command -v deborphan &> /dev/null; then
    echo -e "${GREEN}${MSG_DEBORPHAN}${NC}"
    sudo apt-get purge $(deborphan) -y 2>/dev/null
fi

# Aktualizacja kluczy APT / APT keys update
echo -e "${GREEN}${MSG_APTKEY_UPDATE}${NC}"
sudo apt-key net-update 2>/dev/null

echo -e "${GREEN}${MSG_AUTOCLEAN}${NC}"
sudo apt-get autoclean

echo -e "${GREEN}${MSG_REMOVE_PPA_LISTS}${NC}"
sudo find /etc/apt/sources.list.d/ -type f -name "*.save" -delete

# Kompleksowe czyszczenie Flatpak (System) / Comprehensive Flatpak cleanup (System)
if command -v flatpak &> /dev/null; then
    echo -e "${GREEN}${MSG_FLATPAK_CLEAN_SYS}${NC}"
    sudo flatpak uninstall --unused --system -y
    sudo flatpak uninstall --unused --delete-data -y 2>/dev/null
    sudo flatpak repair --system

    # Usuwanie nieużywanych repozytoriów (remotes) / Removing unused remotes
    USED_REMOTES=$(flatpak list --columns=origin 2>/dev/null | sort -u)
    ALL_REMOTES=$(flatpak remotes --columns=name 2>/dev/null)

    while IFS= read -r remote; do
        if [ -n "$remote" ] && ! echo "$USED_REMOTES" | grep -qx "$remote"; then
            echo -e "${YELLOW}${MSG_FLATPAK_REMOVING_REMOTE} $remote${NC}"
            sudo flatpak remote-delete --force "$remote" 2>/dev/null
        fi
    done <<< "$ALL_REMOTES"

    # Czyszczenie plików tymczasowych i historii Flatpak / Cleaning temp files and history
    sudo rm -rf /var/tmp/flatpak-cache-* 2>/dev/null
    sudo find /var/lib/flatpak -name "*.tmp" -delete 2>/dev/null
    sudo rm -f /var/lib/flatpak/history 2>/dev/null

    # INTELIGENTNE CZYSZCZENIE /var/app (tylko osierocone dane) / SMART /var/app CLEANUP (orphaned data only)
    echo -e "${GREEN}${MSG_FLATPAK_CLEAN_VARAPP_SYS}${NC}"
    INSTALLED_FLATPAKS=$(flatpak list --app --columns=application 2>/dev/null)
    if [ -d "/var/app" ]; then
        for app_dir in /var/app/*; do
            if [ -d "$app_dir" ]; then
                app_id=$(basename "$app_dir")
                if ! echo "$INSTALLED_FLATPAKS" | grep -qx "$app_id"; then
                    echo -e "${YELLOW}${MSG_FLATPAK_REMOVING_VARAPP_SYS} $app_id${NC}"
                    sudo rm -rf "$app_dir"
                fi
            fi
        done
    fi
else
    echo -e "${YELLOW}${MSG_FLATPAK_ABSENT_SYS}${NC}"
fi

echo -e "${GREEN}${MSG_CLEAN_LOGS}${NC}"
sudo journalctl --vacuum-time=7d
sudo find /var/log -type f -name "*.gz" -mtime +7 -delete
sudo find /var/log -type f -name "*.1" -delete

echo -e "${GREEN}${MSG_CLEAN_TMP}${NC}"
sudo find /tmp -type f -atime +3 -delete 2>/dev/null
sudo find /var/tmp -type f -atime +3 -delete 2>/dev/null

echo -e "${GREEN}${MSG_REMOVE_OLD_KERNELS}${NC}"
CURRENT_KERNEL=$(uname -r)
KERNEL_PACKAGES=$(dpkg -l | grep -E 'linux-image-[0-9]' | awk '{print $2}' | grep -v "$CURRENT_KERNEL")
if [ -n "$KERNEL_PACKAGES" ]; then
    echo "${MSG_REMOVING_KERNELS} $KERNEL_PACKAGES"
    sudo apt-get purge $KERNEL_PACKAGES -y
else
    echo "$MSG_ONLY_CURRENT_KERNEL"
fi

echo -e "\n${BLUE}${MSG_PHASE2_TITLE}${NC}"

echo -e "${GREEN}${MSG_CLEAN_USER_CACHE}${NC}"
find ~/.cache -type f -atime +14 \
    ! -path "*/mozilla/*" \
    ! -path "*/google-chrome/*" \
    ! -path "*/chromium/*" \
    ! -path "*/BraveSoftware/*" \
    ! -path "*/opera/*" \
    -delete 2>/dev/null

echo -e "${GREEN}${MSG_CLEAN_THUMBS}${NC}"
find ~/.cache/thumbnails -type f -atime +7 -delete 2>/dev/null

if command -v flatpak &> /dev/null; then
    echo -e "${GREEN}${MSG_FLATPAK_CLEAN_USER}${NC}"
    flatpak uninstall --unused --user -y
    flatpak uninstall --unused --delete-data -y 2>/dev/null || flatpak uninstall --delete-data -y 2>/dev/null
    rm -rf ~/.local/share/flatpak/repo/tmp/* 2>/dev/null
    rm -f ~/.local/share/flatpak/history 2>/dev/null

    # INTELIGENTNE CZYSZCZENIE ~/.var/app (tylko osierocone dane) / SMART ~/.var/app CLEANUP (orphaned data only)
    echo -e "${GREEN}${MSG_FLATPAK_CLEAN_VARAPP_USER}${NC}"
    INSTALLED_FLATPAKS=$(flatpak list --app --columns=application 2>/dev/null)
    if [ -d "$HOME/.var/app" ]; then
        for app_dir in "$HOME/.var/app"/*; do
            if [ -d "$app_dir" ]; then
                app_id=$(basename "$app_dir")
                if ! echo "$INSTALLED_FLATPAKS" | grep -qx "$app_id"; then
                    echo -e "${YELLOW}${MSG_FLATPAK_REMOVING_VARAPP_USER} $app_id${NC}"
                    rm -rf "$app_dir"
                fi
            fi
        done
    fi
fi

echo -e "${GREEN}${MSG_REBUILD_FONTS}${NC}"
fc-cache -fv

echo -e "${GREEN}${MSG_CLEAN_VIRT}${NC}"
USER_ID=$(id -u)
if [ -S "/run/user/$USER_ID/bus" ]; then
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" dconf reset /org/virt-manager/virt-manager/urls/isos 2>/dev/null
    echo -e "${GREEN}${MSG_DCONF_DONE}${NC}"
fi
rm -rf "$HOME/.cache/virt-manager" 2>/dev/null

# Zakończenie / Finish
kill $SUDO_KEEP_ALIVE_PID 2>/dev/null
echo -e "\n${BLUE}====================================================${NC}"
echo -e "${GREEN}${MSG_DONE_TITLE}${NC}"
echo -e "${BLUE}====================================================${NC}"

# Sprawdzanie konieczności restartu (np. po aktualizacji kernela) / Checking if a restart is needed (e.g. after a kernel update)
echo -e "\n${GREEN}${MSG_CHECK_SYSTEM}${NC}"
if [ -f /var/run/reboot-required ]; then
    echo -e "\n${RED}******************************************************${NC}"
    echo -e "${RED} ${MSG_RESTART_WARN1} ${NC}"
    echo -e "${YELLOW}${MSG_RESTART_WARN2}${NC}"
    echo -e "${RED}******************************************************${NC}\n"
else
    echo -e "${GREEN}${MSG_NO_RESTART_NEEDED}${NC}"
fi

if [ "$FWUPD_RESTART_NEEDED" = true ]; then
    echo -e "\n${RED}******************************************************${NC}"
    echo -e "${RED} ${MSG_FWUPD_RESTART_NEEDED} ${NC}"
    echo -e "${YELLOW}${MSG_RESTART_WARN2}${NC}"
    echo -e "${RED}******************************************************${NC}\n"
fi

echo -e "$MSG_PRESS_ENTER"
read -r

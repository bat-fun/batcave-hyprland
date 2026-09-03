#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

APP="BATCAVE"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/.local/state/batcave/backups/$STAMP"

DRY_RUN=0
SKIP_PACKAGES=0
INSTALL_SDDM=0
ASSUME_YES=0

info() { printf '  • %s\n' "$*"; }
ok() { printf '  ✓ %s\n' "$*"; }
warn() { printf '  ! %s\n' "$*" >&2; }
die() { printf '  ✗ %s\n' "$*" >&2; exit 1; }

trap 'printf "\nBATCAVE: installation stopped.\n" >&2' ERR

usage() {
    cat <<'EOF'
BATCAVE installer

Usage:
  ./install.sh [options]

Options:
  --dry-run       Show what would happen without changing anything
  --no-packages   Do not install or modify packages
  --sddm          Install the Batcave SDDM theme
  --yes           Automatically accept safe package/config prompts
  -h, --help      Show this help

Notes:
  • This release targets Arch Linux.
  • Existing files are backed up before replacement.
  • Packages are never removed.
  • Generated/cache state is never copied.
  • Your wallpaper collection is never copied.
  • SDDM is changed only with --sddm or an explicit prompt.
EOF
}

for arg in "$@"; do
    case "$arg" in
        --dry-run)
            DRY_RUN=1
            ;;
        --no-packages)
            SKIP_PACKAGES=1
            ;;
        --sddm)
            INSTALL_SDDM=1
            ;;
        --yes)
            ASSUME_YES=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "Unknown option: $arg"
            ;;
    esac
done

printf '\n'
printf '%s\n' '========================================'
printf '%s\n' '          BATCAVE INSTALLER'
printf '%s\n' '========================================'
printf '\n'

[[ "$EUID" -ne 0 ]] || die \
    "Run this installer as your normal user. It will use sudo when needed."

[[ -r /etc/os-release ]] || die \
    "Cannot identify the operating system."

# shellcheck disable=SC1091
source /etc/os-release

[[ "${ID:-}" == "arch" ]] || die \
    "This release targets Arch Linux. Detected: ${PRETTY_NAME:-unknown}"

command -v pacman >/dev/null 2>&1 || die \
    "pacman was not found."

[[ -d "$ROOT/.config" ]] || die \
    "Repository is missing .config/"

[[ -d "$ROOT/.local/bin" ]] || die \
    "Repository is missing .local/bin/"

if (( INSTALL_SDDM )); then
    [[ -d "$ROOT/sddm/batcave" ]] || die \
        "--sddm was requested, but sddm/batcave/ is missing."
fi

if (( DRY_RUN )); then
    warn "DRY RUN: no changes will be made."
fi

# --------------------------------------------------
# Helpers
# --------------------------------------------------

backup_one() {
    local target="$1"

    [[ -e "$target" || -L "$target" ]] || return 0
    (( DRY_RUN )) && return 0

    mkdir -p "$BACKUP_DIR"

    local relative="${target#$HOME/}"
    local destination="$BACKUP_DIR/$relative"

    mkdir -p "$(dirname "$destination")"
    cp -a "$target" "$destination"
}

install_file() {
    local source="$1"
    local target="$2"

    [[ -f "$source" ]] || return 0

    backup_one "$target"

    if (( DRY_RUN )); then
        info "would install: ${target#$HOME/}"
        return 0
    fi

    mkdir -p "$(dirname "$target")"
    cp -a "$source" "$target"

    ok "installed: ${target#$HOME/}"
}

install_tree() {
    local source_root="$1"
    local target_root="$2"

    [[ -d "$source_root" ]] || return 0

    while IFS= read -r -d '' source; do
        local relative="${source#$source_root/}"

        # Never copy runtime/generated/cache state.
        case "/$relative" in
            */generated/*)
                continue
                ;;
            */cache/*)
                continue
                ;;
            */.cache/*)
                continue
                ;;
        esac

        install_file \
            "$source" \
            "$target_root/$relative"

    done < <(
        find "$source_root" -type f -print0
    )
}

ask_yes_no() {
    local question="$1"
    local default="${2:-N}"
    local answer

    if (( ASSUME_YES )); then
        return 0
    fi

    printf '%s [%s] ' "$question" "$default"
    read -r answer

    if [[ -z "$answer" ]]; then
        answer="$default"
    fi

    [[ "$answer" =~ ^([Yy]|[Yy][Ee][Ss])$ ]]
}

# --------------------------------------------------
# Package management
# --------------------------------------------------

required_packages=(
    hyprland
    waybar
    rofi
    kitty
    thunar
    swaync
    hyprlock
    wlogout
    matugen
    awww
    networkmanager
    network-manager-applet
    blueman
    pavucontrol
    brightnessctl
    playerctl
    pipewire
    pipewire-pulse
    wireplumber
    gtk3
    gtk4
    adw-gtk-theme
    papirus-icon-theme
    ttf-jetbrains-mono-nerd
    git
    fontconfig
)

optional_packages=(
    thunar-volman
)

if (( ! SKIP_PACKAGES )); then

    printf '\n'
    printf '%s\n' 'Dependencies'
    printf '%s\n' '------------'

    missing=()

    for package in "${required_packages[@]}"; do
        pacman -Q "$package" >/dev/null 2>&1 || \
            missing+=("$package")
    done

    if ((${#missing[@]})); then
        info "Missing required packages:"
        printf '    %s\n' "${missing[@]}"

        if (( DRY_RUN )); then
            info "would install missing packages with pacman"
        elif ask_yes_no "Install missing required packages?" "Y"; then
            sudo pacman -S --needed "${missing[@]}"
            ok "required packages installed"
        else
            warn "Required package installation skipped."
        fi
    else
        ok "all required packages are installed"
    fi

    optional_missing=()

    for package in "${optional_packages[@]}"; do
        pacman -Q "$package" >/dev/null 2>&1 || \
            optional_missing+=("$package")
    done

    if ((${#optional_missing[@]})); then
        if (( DRY_RUN )); then
            info "optional Thunar volume support is available"
        elif ask_yes_no "Install optional Thunar volume support?" "N"; then
            sudo pacman -S --needed "${optional_missing[@]}"
            ok "optional Thunar packages installed"
        fi
    fi

    # Code - OSS
    if command -v code >/dev/null 2>&1; then
        ok "Code - OSS found"
    elif pacman -Q code >/dev/null 2>&1; then
        ok "Code - OSS package found"
    else
        if (( DRY_RUN )); then
            info "would offer Code - OSS"
        elif ask_yes_no "Install Code - OSS?" "Y"; then
            sudo pacman -S --needed code
            ok "Code - OSS installed"
        else
            warn "Code - OSS skipped"
        fi
    fi

    # Brave is AUR-only as brave-bin.
    if command -v brave >/dev/null 2>&1 ||
       command -v brave-browser >/dev/null 2>&1; then

        ok "Brave found"

    else

        aur_helper=""

        if command -v paru >/dev/null 2>&1; then
            aur_helper="paru"
        elif command -v yay >/dev/null 2>&1; then
            aur_helper="yay"
        fi

        if [[ -n "$aur_helper" ]]; then

            if (( DRY_RUN )); then
                info "would offer brave-bin via $aur_helper"
            elif ask_yes_no \
                "Brave is not installed. Install brave-bin via $aur_helper?" "Y"
            then
                "$aur_helper" -S --needed brave-bin
                ok "Brave installed"
            else
                warn "Brave skipped"
            fi

        else
            warn "Brave is not installed."
            warn "No paru/yay helper was found; brave-bin was not installed."
        fi
    fi
fi

# --------------------------------------------------
# Backup
# --------------------------------------------------

if (( ! DRY_RUN )); then
    mkdir -p "$BACKUP_DIR"
fi

# --------------------------------------------------
# User configuration
# --------------------------------------------------

printf '\n'
printf '%s\n' 'User configuration'
printf '%s\n' '------------------'

install_tree \
    "$ROOT/.config/hypr" \
    "$HOME/.config/hypr"

install_tree \
    "$ROOT/.config/waybar" \
    "$HOME/.config/waybar"

install_tree \
    "$ROOT/.config/kitty" \
    "$HOME/.config/kitty"

install_tree \
    "$ROOT/.config/rofi" \
    "$HOME/.config/rofi"

install_tree \
    "$ROOT/.config/swaync" \
    "$HOME/.config/swaync"

install_tree \
    "$ROOT/.config/matugen" \
    "$HOME/.config/matugen"

install_tree \
    "$ROOT/.config/batcave" \
    "$HOME/.config/batcave"

install_tree \
    "$ROOT/.local/bin" \
    "$HOME/.local/bin"

if (( ! DRY_RUN )); then
    find "$HOME/.local/bin" \
        -maxdepth 1 \
        -type f \
        -name 'batcave-*' \
        -exec chmod 755 {} +
fi

# --------------------------------------------------
# Desktop preferences
# --------------------------------------------------

printf '\n'
printf '%s\n' 'Desktop defaults'
printf '%s\n' '-----------------'

if command -v gsettings >/dev/null 2>&1; then

    if (( DRY_RUN )); then

        info "would set dark GTK preference"
        info "would set Papirus-Dark icons"
        info "would set Bibata-Modern-Ice cursor"

    else

        gsettings set \
            org.gnome.desktop.interface \
            color-scheme \
            'prefer-dark' \
            2>/dev/null || true

        gsettings set \
            org.gnome.desktop.interface \
            gtk-theme \
            'adw-gtk3-dark' \
            2>/dev/null || true

        gsettings set \
            org.gnome.desktop.interface \
            icon-theme \
            'Papirus-Dark' \
            2>/dev/null || true

        gsettings set \
            org.gnome.desktop.interface \
            cursor-theme \
            'Bibata-Modern-Ice' \
            2>/dev/null || true

        gsettings set \
            org.gnome.desktop.interface \
            cursor-size \
            20 \
            2>/dev/null || true

        fc-cache -f >/dev/null 2>&1 || true

        ok "desktop appearance configured where supported"
    fi

else
    warn "gsettings not found; GTK preferences were left untouched."
fi

# --------------------------------------------------
# Services
# --------------------------------------------------

printf '\n'
printf '%s\n' 'User services'
printf '%s\n' '-------------'

if (( DRY_RUN )); then

    info "would start PipeWire"
    info "would start PipeWire PulseAudio compatibility"
    info "would start WirePlumber"
    info "would start SwayNC"

else

    systemctl --user enable --now \
        pipewire.service \
        >/dev/null 2>&1 || true

    systemctl --user enable --now \
        pipewire-pulse.service \
        >/dev/null 2>&1 || true

    systemctl --user enable --now \
        wireplumber.service \
        >/dev/null 2>&1 || true

    systemctl --user enable --now \
        swaync.service \
        >/dev/null 2>&1 || true

    ok "user services initialized where available"
fi

# --------------------------------------------------
# Network manager
# --------------------------------------------------

if systemctl is-active --quiet NetworkManager.service \
   2>/dev/null; then

    ok "NetworkManager is active"

else

    warn "NetworkManager is not active."
    warn "Existing network management was not forcibly replaced."

fi

# --------------------------------------------------
# SDDM
# --------------------------------------------------

printf '\n'
printf '%s\n' 'SDDM'
printf '%s\n' '----'

if (( ! INSTALL_SDDM )); then

    if [[ -t 0 ]] && ask_yes_no \
        "Install the BATCAVE SDDM login theme?" "N"
    then
        INSTALL_SDDM=1
    else
        info "SDDM left untouched."
    fi

fi

if (( INSTALL_SDDM )); then

    theme_source="$ROOT/sddm/batcave"
    theme_target="/usr/share/sddm/themes/batcave"

    if (( DRY_RUN )); then

        info "would install $theme_target"
        info "would configure /etc/sddm.conf.d/batcave.conf"

    else

        # Back up existing SDDM theme.
        if [[ -e "$theme_target" ||
              -L "$theme_target" ]]; then

            sddm_backup="/var/lib/batcave-sddm-backups/$STAMP"

            sudo mkdir -p "$sddm_backup"
            sudo cp -a "$theme_target" "$sddm_backup/"

            info "existing SDDM theme backed up to:"
            info "$sddm_backup"
        fi

        sudo mkdir -p "$theme_target"
        sudo cp -a "$theme_source"/. "$theme_target"/

        sudo mkdir -p /etc/sddm.conf.d

        tmp="$(mktemp)"

        cat >"$tmp" <<'EOF'
[Theme]
Current=batcave
CursorTheme=Bibata-Modern-Ice
Font=JetBrainsMono Nerd Font
EOF

        sudo install \
            -m 0644 \
            "$tmp" \
            /etc/sddm.conf.d/batcave.conf

        rm -f "$tmp"

        ok "BATCAVE SDDM theme installed"

    fi

else
    info "SDDM unchanged"
fi

# --------------------------------------------------
# Validation
# --------------------------------------------------

printf '\n'
printf '%s\n' 'Validation'
printf '%s\n' '----------'

if (( ! DRY_RUN )); then

    shell_status=0

    while IFS= read -r -d '' script; do
        if ! bash -n "$script"; then
            shell_status=1
            warn "shell syntax error: $script"
        fi
    done < <(
        find "$HOME/.local/bin" \
            -maxdepth 1 \
            -type f \
            -name 'batcave-*' \
            -print0
    )

    if (( shell_status == 0 )); then
        ok "Batcave shell scripts pass syntax checks"
    fi

    check_command() {
        local name="$1"

        if command -v "$name" >/dev/null 2>&1; then
            ok "$name"
        else
            warn "$name not found"
        fi
    }

    check_command hyprland
    check_command waybar
    check_command kitty
    check_command rofi
    check_command thunar
    check_command swaync
    check_command hyprlock
    check_command wlogout
    check_command matugen
    check_command awww

    if command -v fc-match >/dev/null 2>&1 &&
       fc-match "JetBrainsMono Nerd Font" \
           >/dev/null 2>&1; then

        ok "JetBrainsMono Nerd Font resolves"

    else
        warn "JetBrainsMono Nerd Font does not currently resolve"
    fi

fi

# --------------------------------------------------
# Summary
# --------------------------------------------------

printf '\n'
printf '%s\n' '========================================'
printf '%s\n' '     BATCAVE INSTALLATION COMPLETE'
printf '%s\n' '========================================'

if (( DRY_RUN )); then

    warn "Dry run only — no changes were made."

else

    if [[ -d "$BACKUP_DIR" ]] &&
       find "$BACKUP_DIR" \
           -mindepth 1 \
           -print -quit |
       grep -q .; then

        info "Backup:"
        info "$BACKUP_DIR"

    else

        rmdir "$BACKUP_DIR" 2>/dev/null || true
        info "No existing user files needed backup."

    fi

fi

printf '\n'
info "Wallpaper directory: $HOME/Pictures/wallpapers"
info "Generated/cache state was not copied."
info "No packages were removed."
info "SDDM requires --sddm or explicit confirmation."
printf '\n'

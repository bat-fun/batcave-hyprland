#!/usr/bin/env bash

APP="BATCAVE"

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/.local/state/batcave/backups/$STAMP"
WALLPAPER_DIR="$HOME/Pictures/wallpapers"

DRY_RUN=0
SKIP_PACKAGES=0
INSTALL_SDDM=0
ASSUME_YES=0

EDITION=""

MACHINE_TYPE="desktop"

PROGRAM_TERMINAL="kitty"
PROGRAM_BROWSER="brave"
PROGRAM_EDITOR="code"
PROGRAM_FILE_MANAGER="thunar"
PROGRAM_MENU="rofi -show drun"

WALLPAPER_SOURCE=""
WALLPAPER_MODE="none"

SELECTED_PACKAGES=()
MISSING_PACKAGES=()

GPU="unknown"

# --------------------------------------------------
# Shared data
# --------------------------------------------------

CONFIG_PATHS=(
    ".config/hypr"
    ".config/waybar"
    ".config/kitty"
    ".config/rofi"
    ".config/swaync"
    ".config/matugen"
    ".config/batcave"
    ".local/bin"
)

USER_SERVICES=(
    pipewire.service
    pipewire-pulse.service
    wireplumber.service
    swaync.service
)

# --------------------------------------------------
# Output
# --------------------------------------------------

info() {
    printf '  • %s\n' "$*"
}

ok() {
    printf '  ✓ %s\n' "$*"
}

warn() {
    printf '  ! %s\n' "$*" >&2
}

die() {
    printf '  ✗ %s\n' "$*" >&2
    exit 1
}

section() {
    printf '\n%s\n' "$1"
    printf '%*s\n' "${#1}" '' | tr ' ' '-'
}

has_command() {
    command -v "$1" >/dev/null 2>&1
}

trap 'printf "\n%s\n" "$APP: installation stopped." >&2' ERR

# --------------------------------------------------
# UI
# --------------------------------------------------

banner() {
    cat <<'EOF'

╭────────────────────────────────────────────╮
│                                            │
│               B A T C A V E                │
│                                            │
│          Hyprland • Arch Linux             │
│                                            │
╰────────────────────────────────────────────╯

EOF
}

usage() {
    cat <<'EOF'
BATCAVE installer

Usage:
  ./install.sh [options]

Options:
  --dry-run       Preview without changing anything
  --no-packages   Skip package installation
  --sddm          Install BATCAVE SDDM theme
  --yes           Use recommended defaults
  --minimal       Use Minimal edition
  --standard      Use Standard edition
  --full          Use Full edition
  -h, --help      Show this help
EOF
}

ask_yes_no() {
    local question="$1"
    local default="${2:-N}"
    local answer

    (( ASSUME_YES )) && return 0

    printf '%s [%s] ' "$question" "$default" >&2
    read -r answer

    answer="${answer:-$default}"

    [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]
}

confirm_install() {
    (( DRY_RUN || ASSUME_YES )) && return 0

    printf '\n'
    ask_yes_no "Continue with BATCAVE installation?" "Y" ||
        die "Installation cancelled."
}

# --------------------------------------------------
# Arguments
# --------------------------------------------------

parse_args() {
    local arg

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

            --minimal)
                EDITION="minimal"
                ;;

            --standard)
                EDITION="standard"
                ;;

            --full)
                EDITION="full"
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
}

# --------------------------------------------------
# Preflight
# --------------------------------------------------

preflight() {
    section "System check"

    [[ "$EUID" -ne 0 ]] ||
        die "Run the installer as your normal user."

    [[ -r /etc/os-release ]] ||
        die "Cannot identify the operating system."

    # shellcheck disable=SC1091
    source /etc/os-release

    [[ "${ID:-}" == "arch" ]] ||
        die "BATCAVE targets Arch Linux. Detected: ${PRETTY_NAME:-unknown}"

    has_command pacman ||
        die "pacman was not found."

    has_command sudo ||
        die "sudo was not found."

    [[ -d "$ROOT/.config" ]] ||
        die "Repository is missing .config/"

    [[ -d "$ROOT/.local/bin" ]] ||
        die "Repository is missing .local/bin/"

    if compgen -G "/sys/class/power_supply/BAT*" >/dev/null 2>&1; then
        MACHINE_TYPE="laptop"
    fi

    ok "Arch Linux"
    ok "pacman"
    ok "sudo"
    ok "machine: $MACHINE_TYPE"
    ok "repository structure"

    if (( DRY_RUN )); then
        warn "DRY RUN: no changes will be made."
    fi
}

# --------------------------------------------------
# Backup
# --------------------------------------------------

backup_one() {
    local target="$1"
    local relative
    local destination

    [[ -e "$target" || -L "$target" ]] || return 0
    (( DRY_RUN )) && return 0

    mkdir -p "$BACKUP_DIR"

    relative="${target#$HOME/}"
    destination="$BACKUP_DIR/$relative"

    mkdir -p "$(dirname "$destination")"

    cp -a "$target" "$destination"
}
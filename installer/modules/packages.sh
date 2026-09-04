#!/usr/bin/env bash

# ============================================================
# BATCAVE PACKAGE PROFILES
# ============================================================

CORE_PACKAGES=(
    hyprland
    waybar
    rofi
    kitty
    hyprlock
    wlogout
    ttf-jetbrains-mono-nerd
    fontconfig
)

DESKTOP_PACKAGES=(
    thunar
    swaync
    brightnessctl
    playerctl
)

AUDIO_PACKAGES=(
    pipewire
    pipewire-pulse
    wireplumber
    pavucontrol
)

NETWORK_PACKAGES=(
    networkmanager
    network-manager-applet
)

BLUETOOTH_PACKAGES=(
    blueman
)

THEME_PACKAGES=(
    matugen
    gtk3
    gtk4
    adw-gtk-theme
    papirus-icon-theme
)

WALLPAPER_PACKAGES=(
    awww
)

EXTRA_PACKAGES=(
    git
    thunar-volman
)

SDDM_PACKAGES=(
    sddm
)

# ============================================================
# FEATURE FLAGS
# ============================================================

FEATURE_DESKTOP=0
FEATURE_AUDIO=0
FEATURE_NETWORK=0
FEATURE_BLUETOOTH=0
FEATURE_THEMING=0
FEATURE_WALLPAPER=0
FEATURE_SDDM=0


# ============================================================
# EDITION
# ============================================================

choose_edition() {
    [[ -n "$EDITION" ]] && return 0

    section "Choose your BATCAVE edition"

    cat <<'EOF'

  1) Minimal
     Core BATCAVE.
     Lightweight and clean.

  2) Standard  [recommended]
     Complete daily-driver setup.
     Audio, network, Bluetooth, notifications, wallpaper and theming.

  3) Full
     Everything BATCAVE offers.
     Includes SDDM support.

  4) Custom
     Choose the feature groups yourself.

EOF

    local choice

    if (( ASSUME_YES )); then
        choice=2
    else
        printf "Select [2]: "
        read -r choice
        choice="${choice:-2}"
    fi

    case "$choice" in
        1)
            EDITION="minimal"
            ;;

        2)
            EDITION="standard"
            ;;

        3)
            EDITION="full"
            ;;

        4)
            EDITION="custom"
            ;;

        *)
            die "Invalid edition."
            ;;
    esac
}

# ============================================================
# FEATURE PROFILES
# ============================================================

reset_features() {
    FEATURE_DESKTOP=0
    FEATURE_AUDIO=0
    FEATURE_NETWORK=0
    FEATURE_BLUETOOTH=0
    FEATURE_THEMING=0
    FEATURE_WALLPAPER=0
    FEATURE_SDDM=0
}

apply_edition_profile() {
    reset_features

    case "$EDITION" in

        minimal)
            # Core only.
            ;;

        standard)
            FEATURE_DESKTOP=1
            FEATURE_AUDIO=1
            FEATURE_NETWORK=1
            FEATURE_BLUETOOTH=1
            FEATURE_THEMING=1
            FEATURE_WALLPAPER=1
            ;;

        full)
            FEATURE_DESKTOP=1
            FEATURE_AUDIO=1
            FEATURE_NETWORK=1
            FEATURE_BLUETOOTH=1
            FEATURE_THEMING=1
            FEATURE_WALLPAPER=1
            FEATURE_SDDM=1
            ;;

        custom)
            choose_custom_features
            ;;

        *)
            die "Unknown edition: $EDITION"
            ;;
    esac
}

# ============================================================
# CUSTOM
# ============================================================

choose_custom_features() {
    section "Custom components"

    cat >&2 <<'EOF'

Choose the feature groups you want.

  1) Desktop utilities
     Thunar, notifications, brightness and media controls.

  2) Audio
     PipeWire, WirePlumber and volume controls.

  3) Network
     NetworkManager and tray applet.

  4) Bluetooth
     Blueman Bluetooth manager.

  5) Appearance
     GTK themes, icons and colors.

  6) Wallpaper
     Dynamic wallpaper and transitions.

  7) SDDM
     BATCAVE login screen theme.

EOF

    local choices
    if (( ASSUME_YES )); then
        choices="1 2 3 4 5 6"
    else
        printf 'Select features [1 2 3 4 5 6]: ' >&2
        read -r choices
    fi

    local choice
    local selected_features=()
    while read -r choice; do
        selected_features+=("$choice")
    done < <(printf '%s\n' "$choices" | tr ' ' '\n')

    for choice in "${selected_features[@]}"; do
        case "$choice" in
            1)
                FEATURE_DESKTOP=1
                ;;
            2)
                FEATURE_AUDIO=1
                ;;
            3)
                FEATURE_NETWORK=1
                ;;
            4)
                FEATURE_BLUETOOTH=1
                ;;
            5)
                FEATURE_THEMING=1
                ;;
            6)
                FEATURE_WALLPAPER=1
                ;;
            7)
                FEATURE_SDDM=1
                ;;
            *)
                warn "Ignoring invalid feature selection: $choice"
                ;;
        esac
    done
}

# ============================================================
# PACKAGE PLAN
# ============================================================

plan_packages() {
    SELECTED_PACKAGES=()
    MISSING_PACKAGES=()

    apply_edition_profile

    SELECTED_PACKAGES+=(
        "${CORE_PACKAGES[@]}"
    )

    if (( FEATURE_DESKTOP )); then
        SELECTED_PACKAGES+=(
            "${DESKTOP_PACKAGES[@]}"
        )
    fi

    if (( FEATURE_AUDIO )); then
        SELECTED_PACKAGES+=(
            "${AUDIO_PACKAGES[@]}"
        )
    fi

    if (( FEATURE_NETWORK )); then
        SELECTED_PACKAGES+=(
            "${NETWORK_PACKAGES[@]}"
        )
    fi

    if (( FEATURE_BLUETOOTH )); then
        SELECTED_PACKAGES+=(
            "${BLUETOOTH_PACKAGES[@]}"
        )
    fi

    if (( FEATURE_THEMING )); then
        SELECTED_PACKAGES+=(
            "${THEME_PACKAGES[@]}"
        )
    fi

    if (( FEATURE_WALLPAPER )); then
        SELECTED_PACKAGES+=(
            "${WALLPAPER_PACKAGES[@]}"
        )
    fi

    if [[ "$EDITION" == "full" ]]; then
        SELECTED_PACKAGES+=(
            "${EXTRA_PACKAGES[@]}"
        )
    fi

    if (( FEATURE_SDDM )); then
        SELECTED_PACKAGES+=(
            "${SDDM_PACKAGES[@]}"
        )
    fi

    (( SKIP_PACKAGES )) && return 0

    local -A seen=()
    local package

    for package in "${SELECTED_PACKAGES[@]}"; do
        [[ "${seen[$package]:-0}" == 1 ]] && continue

        seen["$package"]=1

        if ! pacman -Q "$package" >/dev/null 2>&1; then
            MISSING_PACKAGES+=("$package")
        fi
    done
}

# ============================================================
# INSTALL
# ============================================================

install_packages() {
    section "Packages"

    if (( SKIP_PACKAGES )); then
        info "package installation skipped"
        return 0
    fi

    if ((${#MISSING_PACKAGES[@]} == 0)); then
        ok "all selected packages are already installed"
        return 0
    fi

    printf \
        '  %d package(s) will be installed:\n' \
        "${#MISSING_PACKAGES[@]}"

    printf '    • %s\n' "${MISSING_PACKAGES[@]}"

    if (( DRY_RUN )); then
        info "package installation preview complete"
        return 0
    fi

    sudo pacman \
        -S \
        --needed \
        "${MISSING_PACKAGES[@]}"

    ok "packages installed"
}
#!/usr/bin/env bash

CONFIG_FILES=()

build_config_list() {
    CONFIG_FILES=(
        ".config/hypr/hyprland.lua"
        ".config/hypr/modules/misc.lua"
        ".config/hypr/modules/decoration.lua"
        ".config/hypr/modules/autostart.lua"
        ".config/hypr/modules/animation.lua"
        ".config/hypr/modules/rules.lua"
        ".config/hypr/modules/binds.lua"
        ".config/hypr/modules/monitors.lua"
        ".config/hypr/modules/env.lua"
        ".config/hypr/modules/input.lua"
        ".config/hypr/modules/programs.lua"
        ".config/hypr/modules/layout.lua"
        ".config/hypr/hyprlock.conf"

        ".config/waybar/style.css"
        ".config/waybar/config.jsonc"

        ".config/kitty/kitty.conf"

        ".config/rofi/batcave.rasi"
        ".config/rofi/config.rasi"
    )

    if (( FEATURE_DESKTOP )); then
        CONFIG_FILES+=(
            ".config/swaync/style.css"
        )
    fi

    if (( FEATURE_THEMING )); then
        CONFIG_FILES+=(
            ".config/matugen/config.toml"
            ".config/matugen/templates/colors.css"
            ".config/matugen/templates/rofi-colors.rasi"
            ".config/matugen/templates/kitty-colors.conf"
            ".config/matugen/templates/hyprlock-colors.conf"
        )
    fi
}

install_config() {
    build_config_list

    section "Configuration"

    for file in "${CONFIG_FILES[@]}"; do
        if (( DRY_RUN )); then
            printf '  • would install %s\n' "$file"
            continue
        fi

        backup_one "$HOME/$file"
        install_one "$file"
    done

    if (( DRY_RUN )); then
        printf '  • configuration installation preview complete\n'
    else
        printf '  ✓ configuration installed\n'
    fi
}
configure_appearance() {
    section "Appearance"

    if (( FEATURE_THEMING )); then
        if (( DRY_RUN )); then
            printf '  • would apply dark GTK appearance\n'
            printf '  • would use Papirus-Dark icons\n'
            printf '  • would use Bibata-Modern-Ice cursor\n'
            return
        fi

        printf '  • applying dark GTK appearance\n'
        printf '  • configuring Papirus-Dark icons\n'
        printf '  • configuring Bibata-Modern-Ice cursor\n'

        # GTK appearance
        if command -v gsettings >/dev/null 2>&1; then
            gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark" 2>/dev/null || true
            gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark" 2>/dev/null || true
            gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Ice" 2>/dev/null || true
        fi

        printf '  ✓ appearance configured\n'
    else
        printf '  • theming skipped\n'
    fi
}
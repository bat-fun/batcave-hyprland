#!/usr/bin/env bash

check_command() {
    local command="$1"

    if command -v "$command" >/dev/null 2>&1; then
        ok "$command"
    else
        warn "$command not found"
    fi
}

review() {
    section "Installation plan"

    printf '\n'

    printf '%s\n' '  Edition'
    printf '    %s\n' "$EDITION"

    printf '\n'
    printf '%s\n' '  Programs'
    printf '    Terminal      %s\n' "$PROGRAM_TERMINAL"
    printf '    Browser       %s\n' "$PROGRAM_BROWSER"
    printf '    Editor        %s\n' "$PROGRAM_EDITOR"
    printf '    File manager  %s\n' "$PROGRAM_FILE_MANAGER"

    printf '\n'
    printf '%s\n' '  System'
    printf '    Machine       %s\n' "$MACHINE_TYPE"

    if [[ "$GPU" != "unknown" ]]; then
        printf '    GPU           %s\n' "$GPU"
    fi

    printf '\n'
    printf '%s\n' '  Features'

    if (( FEATURE_DESKTOP )); then
        printf '    Desktop       Yes\n'
    else
        printf '    Desktop       No\n'
    fi

    if (( FEATURE_AUDIO )); then
        printf '    Audio         Yes\n'
    else
        printf '    Audio         No\n'
    fi

    if (( FEATURE_NETWORK )); then
        printf '    Network       Yes\n'
    else
        printf '    Network       No\n'
    fi

    if (( FEATURE_BLUETOOTH )); then
        printf '    Bluetooth     Yes\n'
    else
        printf '    Bluetooth     No\n'
    fi

    if (( FEATURE_THEMING )); then
        printf '    Theming       Yes\n'
    else
        printf '    Theming       No\n'
    fi

    if (( FEATURE_WALLPAPER )); then
        printf '    Wallpaper     Yes\n'
    else
        printf '    Wallpaper     No\n'
    fi

    if (( FEATURE_SDDM )); then
        printf '    SDDM          Yes\n'
    else
        printf '    SDDM          No\n'
    fi

    printf '\n'
    printf '%s\n' '  Wallpaper'

    if [[ -n "$WALLPAPER_SOURCE" ]]; then
        printf '    Selected      %s\n' \
            "$(basename "$WALLPAPER_SOURCE")"
    else
        printf '    Selected      None\n'
    fi

    printf '\n'
    printf '%s\n' '  Packages'

    if (( SKIP_PACKAGES )); then
        printf '    Installation  Skipped\n'
    else
        printf '    New           %d\n' \
            "${#MISSING_PACKAGES[@]}"
    fi

    printf '\n'
    printf '%s\n' '  Backup'

    if (( DRY_RUN )); then
        printf '    Status        Preview only\n'
    else
        printf '    Location      %s\n' "$BACKUP_DIR"
    fi
}

validate() {
    section "Verification"

    if (( DRY_RUN )); then
        info "verification skipped during dry run"
        return 0
    fi

    local command

    for command in \
        hyprland \
        waybar \
        kitty \
        rofi \
        hyprlock \
        wlogout \
        matugen \
        awww; do

        check_command "$command"
    done

    [[ -f "$HOME/.config/hypr/modules/programs.lua" ]] &&
        ok "program configuration exists" ||
        warn "program configuration missing"

    local failed=0
    local script

    while IFS= read -r -d '' script; do
        if ! bash -n "$script"; then
            failed=1
            warn "shell syntax error: $script"
        fi
    done < <(
        find "$HOME/.local/bin" \
            -maxdepth 1 \
            -type f \
            -name "batcave-*" \
            -print0 \
            2>/dev/null
    )

    (( failed == 0 )) &&
        ok "BATCAVE scripts pass syntax checks"

    if has_command fc-match &&
       fc-match "JetBrainsMono Nerd Font" >/dev/null 2>&1; then

        ok "JetBrainsMono Nerd Font resolves"
    else
        warn "JetBrainsMono Nerd Font does not currently resolve"
    fi

    if [[ -d "$WALLPAPER_DIR" ]]; then
        local count

        count="$(
            find "$WALLPAPER_DIR" \
                -maxdepth 1 \
                -type f \
                2>/dev/null |
            wc -l
        )"

        if (( count > 0 )); then
            ok "wallpaper collection: $count file(s)"
        else
            warn "wallpaper collection is empty"
        fi
    fi
}

summary() {
    section "BATCAVE is ready"

    if (( DRY_RUN )); then
        warn "Dry run only — no changes were made."
        return 0
    fi

    ok "edition: $EDITION"
    ok "terminal: $PROGRAM_TERMINAL"
    ok "browser: $PROGRAM_BROWSER"
    ok "editor: $PROGRAM_EDITOR"
    ok "file manager: $PROGRAM_FILE_MANAGER"

    if [[ -n "$WALLPAPER_SOURCE" ]]; then
        ok "wallpaper: $(basename "$WALLPAPER_SOURCE")"
    else
        warn "no wallpaper selected"
        info "add images to $WALLPAPER_DIR"
    fi

    if [[ -d "$BACKUP_DIR" ]] &&
       find "$BACKUP_DIR" \
           -mindepth 1 \
           -print -quit \
           2>/dev/null |
       grep -q .; then

        info "backup: $BACKUP_DIR"
    else
        info "no existing user files needed backup"
    fi

    printf '\n'
    printf '%s\n' 'Next steps:'
    printf '%s\n' "  1. Add wallpapers to $WALLPAPER_DIR if needed."
    printf '%s\n' '  2. Log out.'
    printf '%s\n' '  3. Select Hyprland from your login manager.'
    printf '\n'
}
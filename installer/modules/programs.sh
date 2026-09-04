#!/usr/bin/env bash

choose_program() {
    local label="$1"
    local preferred="$2"

    shift 2

    local -a found=()
    local candidate
    local answer
    local default_index=1
    local i=1

    for candidate in "$@"; do
        if command -v "$candidate" >/dev/null 2>&1; then
            found+=("$candidate")

            [[ "$candidate" == "$preferred" ]] &&
                default_index="$i"

            ((i++))
        fi
    done

    printf '\n%s\n' "$label" >&2

    if ((${#found[@]} == 0)); then
        warn "No supported $label detected."

        if (( ASSUME_YES )); then
            printf '%s\n' "$preferred"
        else
            printf 'Enter command [%s]: ' "$preferred" >&2
            read -r answer
            printf '%s\n' "${answer:-$preferred}"
        fi

        return
    fi

    i=1

    for candidate in "${found[@]}"; do
        if (( i == default_index )); then
            printf \
                '  %d) %s [recommended] (%s)\n' \
                "$i" \
                "$candidate" \
                "$(command -v "$candidate")" \
                >&2
        else
            printf \
                '  %d) %s (%s)\n' \
                "$i" \
                "$candidate" \
                "$(command -v "$candidate")" \
                >&2
        fi

        ((i++))
    done

    printf '  %d) Other\n' "$i" >&2

    if (( ASSUME_YES )); then
        printf '%s\n' "${found[default_index-1]}"
        return
    fi

    while true; do
        printf 'Select [%s]: ' "$default_index" >&2
        read -r answer

        answer="${answer:-$default_index}"

        if [[ "$answer" =~ ^[0-9]+$ ]] &&
           (( answer >= 1 && answer <= i )); then

            if (( answer == i )); then
                printf 'Command: ' >&2
                read -r answer

                [[ -n "$answer" ]] || continue

                printf '%s\n' "$answer"
            else
                printf '%s\n' "${found[answer-1]}"
            fi

            return
        fi

        warn "Invalid selection."
    done
}

plan_programs() {
    section "Program setup"

    PROGRAM_TERMINAL="$(
        choose_program \
            "Terminal" \
            "kitty" \
            kitty \
            foot \
            ghostty \
            alacritty \
            wezterm
    )"

    PROGRAM_FILE_MANAGER="$(
        choose_program \
            "File manager" \
            "thunar" \
            thunar \
            dolphin \
            nautilus \
            nemo \
            pcmanfm-qt \
            pcmanfm
    )"

    PROGRAM_EDITOR="$(
        choose_program \
            "Editor / IDE" \
            "nvim" \
            nvim \
            vim \
            code \
            codium \
            emacs
    )"

    PROGRAM_BROWSER="$(
        choose_program \
            "Browser" \
            "firefox" \
            firefox \
            brave \
            brave-browser \
            chromium \
            google-chrome
    )"

    PROGRAM_MENU="rofi -show drun"
}

write_programs() {
    local target="$HOME/.config/hypr/modules/programs.lua"
    local tmp

    section "Program configuration"

    if (( DRY_RUN )); then
        info "would configure ${target#$HOME/}"
        info "terminal: $PROGRAM_TERMINAL"
        info "browser: $PROGRAM_BROWSER"
        info "editor: $PROGRAM_EDITOR"
        info "file manager: $PROGRAM_FILE_MANAGER"
        return 0
    fi

    tmp="$(mktemp)"

    cat >"$tmp" <<EOF
---------------------
---- MY PROGRAMS ----
---------------------

terminal    = "$PROGRAM_TERMINAL"
fileManager = "$PROGRAM_FILE_MANAGER"
menu        = "$PROGRAM_MENU"
code        = "$PROGRAM_EDITOR"
browser     = "$PROGRAM_BROWSER"
EOF

    install \
        -m 0644 \
        "$tmp" \
        "$target"

    rm -f "$tmp"

    ok "program defaults configured"
}
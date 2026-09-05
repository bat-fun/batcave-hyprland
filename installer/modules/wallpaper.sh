#!/usr/bin/env bash

find_wallpapers() {
    [[ -d "$WALLPAPER_DIR" ]] || return 0

    find "$WALLPAPER_DIR" \
        -maxdepth 1 \
        -type f \
        \( \
            -iname "*.jpg" \
            -o -iname "*.jpeg" \
            -o -iname "*.png" \
            -o -iname "*.webp" \
            -o -iname "*.avif" \
        \) \
        -print 2>/dev/null |
        sort
}

find_bundled_wallpaper() {
    [[ -d "$ROOT/assets/wallpapers" ]] || return 0

    find "$ROOT/assets/wallpapers" \
        -maxdepth 1 \
        -type f \
        \( \
            -iname "*.jpg" \
            -o -iname "*.jpeg" \
            -o -iname "*.png" \
            -o -iname "*.webp" \
            -o -iname "*.avif" \
        \) \
        -print 2>/dev/null |
        sort |
        head -n1
}

random_wallpaper() {
    local -n list_ref="$1"
    local count="${#list_ref[@]}"
    local index

    (( count > 0 )) || return 1

    index=$(( RANDOM % count ))
    printf '%s\n' "${list_ref[index]}"
}

choose_wallpaper_page() {
    local -a wallpapers=("$@")
    local total="${#wallpapers[@]}"
    local page=0
    local page_size=12
    local answer
    local start
    local end
    local i
    local total_pages

    total_pages=$(( (total + page_size - 1) / page_size ))

    while true; do
        printf '\n'
        printf 'Choose wallpaper\n'
        printf 'Page %d/%d\n\n' \
            "$((page + 1))" \
            "$total_pages"

        start=$(( page * page_size ))
        end=$(( start + page_size ))

        (( end > total )) && end="$total"

        i="$start"

        while (( i < end )); do
            printf \
                '  %d) %s\n' \
                "$(( i - start + 1 ))" \
                "$(basename "${wallpapers[i]}")"

            ((i++))
        done

        printf '\n'

        (( page + 1 < total_pages )) &&
            printf '  n) Next page\n'

        (( page > 0 )) &&
            printf '  p) Previous page\n'

        printf \
            '  r) Random\n' \
            '  q) Back\n'

        printf 'Select [r]: '
        read -r answer

        answer="${answer:-r}"

        case "$answer" in
            n)
                if (( page + 1 < total_pages )); then
                    ((page++))
                fi
                ;;

            p)
                if (( page > 0 )); then
                    ((page--))
                fi
                ;;

            r)
                WALLPAPER_SOURCE="$(random_wallpaper wallpapers)"
                WALLPAPER_MODE="random"
                return 0
                ;;

            q)
                return 0
                ;;

            ''|*[!0-9]*)
                warn "Invalid selection."
                ;;

            *)
                if (( answer >= 1 && answer <= end - start )); then
                    WALLPAPER_SOURCE="${wallpapers[start + answer - 1]}"
                    WALLPAPER_MODE="selected"
                    return 0
                fi

                warn "Invalid selection."
                ;;
        esac
    done
}

plan_wallpaper() {
    WALLPAPER_SOURCE=""

    if (( ! FEATURE_WALLPAPER )); then
        return 0
    fi

    section "Wallpaper"


    local -a wallpapers=()
    local bundled
    local choice

    mapfile -t wallpapers < <(find_wallpapers)

    if ((${#wallpapers[@]})); then
        ok "found ${#wallpapers[@]} wallpaper(s)"

        printf '\n'
        printf '  1) Random\n'
        printf '  2) Choose manually\n'
        printf '  3) Skip for now\n'

        if (( ASSUME_YES )); then
            choice=1
        else
            printf 'Select [1]: '
            read -r choice
            choice="${choice:-1}"
        fi

        case "$choice" in
            1)
                WALLPAPER_SOURCE="$(random_wallpaper wallpapers)"
                WALLPAPER_MODE="random"
                ;;

            2)
                choose_wallpaper_page "${wallpapers[@]}"
                ;;

            3)
                WALLPAPER_MODE="none"
                ;;

            *)
                die "Invalid wallpaper selection."
                ;;
        esac

        return 0
    fi

    bundled="$(find_bundled_wallpaper || true)"

    if [[ -n "$bundled" ]]; then
        warn "No personal wallpaper was found."

        if ask_yes_no \
            "Add the bundled BATCAVE wallpaper?" \
            "Y"; then

            WALLPAPER_SOURCE="$bundled"
            WALLPAPER_MODE="bundled"

            info "bundled wallpaper selected:"
            info "$(basename "$bundled")"
        fi
    else
        warn "No wallpaper found."
    fi

    info "Add your own images to:"
    info "$WALLPAPER_DIR"
}

initialize_wallpaper() {
    if (( ! FEATURE_WALLPAPER )); then
        return 0
    fi

    [[ -n "$WALLPAPER_SOURCE" ]] || return 0

    section "Wallpaper"

    if (( DRY_RUN )); then
        info "would initialize wallpaper"
        info "$WALLPAPER_SOURCE"
        return 0
    fi

    if [[ "$WALLPAPER_MODE" == "bundled" ]]; then
        mkdir -p "$WALLPAPER_DIR"

        local target="$WALLPAPER_DIR/$(basename "$WALLPAPER_SOURCE")"

        if [[ ! -e "$target" ]]; then
            cp "$WALLPAPER_SOURCE" "$target"
            ok "BATCAVE wallpaper installed"
        else
            info "BATCAVE wallpaper already exists"
        fi

        WALLPAPER_SOURCE="$target"
    fi

    if [[ "$WALLPAPER_MODE" == "selected" ]]; then
        if command -v awww >/dev/null 2>&1; then
            if awww img "$WALLPAPER_SOURCE" \
                --transition-type grow \
                --transition-duration 0.8; then

                mkdir -p "$HOME/.cache/batcave"

                printf '%s\n' "$WALLPAPER_SOURCE" \
                    > "$HOME/.cache/batcave/last-wallpaper"

                ok "selected wallpaper applied"
            else
                warn "selected wallpaper could not be applied"
            fi
        else
            warn "awww is not available; wallpaper not applied"
        fi

    elif [[ "$WALLPAPER_MODE" == "bundled" ]]; then
        if command -v awww >/dev/null 2>&1; then
            if awww img "$WALLPAPER_SOURCE" \
                --transition-type grow \
                --transition-duration 0.8; then

                mkdir -p "$HOME/.cache/batcave"

                printf '%s\n' "$WALLPAPER_SOURCE" \
                    > "$HOME/.cache/batcave/last-wallpaper"

                ok "bundled wallpaper applied"
            else
                warn "bundled wallpaper could not be applied"
            fi
        else
            warn "awww is not available; wallpaper not applied"
        fi

        elif [[ "$WALLPAPER_MODE" == "random" ]]; then
        if command -v awww >/dev/null 2>&1; then
            if awww img "$WALLPAPER_SOURCE" \
                --transition-type grow \
                --transition-duration 0.8; then

                mkdir -p "$HOME/.cache/batcave"

                printf '%s\n' "$WALLPAPER_SOURCE" \
                    > "$HOME/.cache/batcave/last-wallpaper"

                ok "random wallpaper applied"
            else
                warn "random wallpaper could not be applied"
            fi
        else
            warn "awww is not available; wallpaper not applied"
        fi
    fi
}
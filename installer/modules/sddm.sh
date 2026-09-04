#!/usr/bin/env bash

plan_sddm() {
    INSTALL_SDDM=0

    # Only Full/Custom editions may opt into SDDM.
    if [[ "$EDITION" != "full" && "$EDITION" != "custom" ]]; then
        return 0
    fi

    (( FEATURE_SDDM )) || return 0

    section "Login screen"

    info "BATCAVE SDDM theme selected."

    if (( ASSUME_YES || DRY_RUN )); then
        INSTALL_SDDM=1
        return 0
    fi

    if ask_yes_no \
        "Install BATCAVE SDDM theme?" \
        "Y"; then
        INSTALL_SDDM=1
    else
        info "SDDM: skipped"
    fi
}

install_sddm() {
    (( INSTALL_SDDM )) || return 0

    local source="$ROOT/sddm/batcave"
    local target="/usr/share/sddm/themes/batcave"
    local config="/etc/sddm.conf.d/batcave.conf"
    local tmp

    [[ -d "$source" ]] ||
        die "SDDM requested, but sddm/batcave/ is missing."

    section "SDDM"

    if (( DRY_RUN )); then
        info "would install $target"
        info "would configure $config"
        return 0
    fi

    if [[ -e "$target" || -L "$target" ]]; then
        local backup_path="/var/lib/batcave-sddm-backups/$STAMP"

        sudo mkdir -p "$backup_path"

        sudo cp -a \
            "$target" \
            "$backup_path/"
    fi

    sudo mkdir -p \
        "$target" \
        "/etc/sddm.conf.d"

    sudo cp -a \
        "$source"/. \
        "$target"/

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
        "$config"

    rm -f "$tmp"

    ok "SDDM theme installed"
}
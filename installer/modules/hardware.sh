#!/usr/bin/env bash

plan_hardware() {
    section "Hardware"

    GPU="unknown"

    if command -v lspci >/dev/null 2>&1; then
        GPU="$(
            lspci 2>/dev/null |
            grep -Ei "VGA|3D|Display" |
            head -n1 ||
            true
        )"
    fi

    [[ -n "$GPU" ]] ||
        GPU="unknown"

    info "machine: $MACHINE_TYPE"

    [[ "$GPU" != "unknown" ]] &&
        info "GPU: $GPU"

    info "monitor configuration will remain unchanged"
}

install_hardware() {
    :
}
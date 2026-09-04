#!/usr/bin/env bash

plan_services() {
    :
}

install_services() {
    section "User services"

    local services=()

    if (( FEATURE_AUDIO )); then
        services+=(
            pipewire.service
            pipewire-pulse.service
            wireplumber.service
        )
    fi

    if (( FEATURE_DESKTOP )); then
        services+=(
            swaync.service
        )
    fi

    if ((${#services[@]} == 0)); then
        info "no optional user services selected"
        return 0
    fi

    local service

    for service in "${services[@]}"; do
        if (( DRY_RUN )); then
            info "would enable --now $service"
            continue
        fi

        systemctl \
            --user \
            enable \
            --now \
            "$service" \
            >/dev/null 2>&1 ||
            warn "$service could not be started"
    done

    if (( DRY_RUN )); then
        info "service setup preview complete"
    else
        ok "user services processed"
    fi
}
#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$ROOT/installer/init.sh"
source "$ROOT/installer/modules/packages.sh"
source "$ROOT/installer/modules/programs.sh"
source "$ROOT/installer/modules/wallpaper.sh"
source "$ROOT/installer/modules/hardware.sh"
source "$ROOT/installer/modules/config.sh"
source "$ROOT/installer/modules/services.sh"
source "$ROOT/installer/modules/sddm.sh"
source "$ROOT/installer/modules/validate.sh"

main() {
    parse_args "$@"

    banner
    preflight

    choose_edition
    plan_packages
    plan_programs
    plan_wallpaper
    plan_hardware
    plan_services
    plan_sddm

    review
    confirm_install

    install_packages
    install_config
    write_programs
    install_hardware
    install_services
    install_sddm
    initialize_wallpaper
    configure_appearance

    validate
    summary
}

main "$@"
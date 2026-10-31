#!/usr/bin/bash
source "$CTX/build_files/lib.sh"

mapfile -t PKGS < <(read_list "$CTX/config/packages.txt")
if ((${#PKGS[@]})); then
    log "Installing ${#PKGS[@]} packages"
    dnf5 install -y --setopt=install_weak_deps=False --skip-unavailable "${PKGS[@]}"
fi

mapfile -t REMOVE < <(read_list "$CTX/config/packages-remove.txt")
if ((${#REMOVE[@]})); then
    log "Removing ${#REMOVE[@]} packages"
    dnf5 remove -y "${REMOVE[@]}"
fi
dnf5 clean all

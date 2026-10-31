#!/usr/bin/bash
source "$CTX/build_files/lib.sh"
systemctl enable myos-firstboot.service
# Services that Bazzite already enables (bluetooth, cups, fwupd, flatpak update timers) are untouched.
log "Services configured"

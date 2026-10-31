#!/usr/bin/bash
source "$CTX/build_files/lib.sh"

# dconf: make sure the 'local' system database is in the user profile, then compile.
PROFILE=/etc/dconf/profile/user
if ! grep -q '^system-db:local' "$PROFILE"; then
    sed -i '/^user-db:user/a system-db:local' "$PROFILE"
fi
dconf update
[ -f /etc/dconf/db/local ] || { warn "dconf local db was not produced"; exit 1; }

# Sanity checks: fail the build early rather than ship a half-themed OS.
for f in /usr/share/themes/MyOS/gnome-shell/gnome-shell.css \
         /usr/share/backgrounds/"${MYOS_ID}"/myos-light.png \
         /usr/share/backgrounds/"${MYOS_ID}"/myos-dark.png \
         /usr/share/plymouth/themes/myos/logo.png \
         /usr/share/ublue-os/just/60-myos.just; do
    [ -s "$f" ] || { warn "missing expected file: $f"; exit 1; }
done
[ -d /usr/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com ] || warn "Dash to Panel is missing: the taskbar will not appear (see /usr/share/myos/extensions-installed.txt)"
[ -d /usr/share/gnome-shell/extensions/arcmenu@arcmenu.com ] || warn "ArcMenu is missing: the Start menu will not appear"

# Initramfs: include the Plymouth theme and add boot-splash kargs (usr/lib/bootc/kargs.d).
if [ "${REGENERATE_INITRAMFS:-1}" = 1 ]; then
    KVER="$(ls -1 /usr/lib/modules | sort -V | tail -n1)"
    log "Regenerating initramfs for ${KVER}"
    DRACUT_NO_XATTR=1 /usr/bin/dracut --no-hostonly --kver "$KVER" --reproducible --zstd -v --add ostree \
        -f "/usr/lib/modules/${KVER}/initramfs.img"
    chmod 0600 "/usr/lib/modules/${KVER}/initramfs.img"
fi

# Tidy build leftovers (the bootc lint step complains about stray /var content).
rm -rf /var/cache/* /var/log/* /tmp/* 2>/dev/null || true
log "Build finished for ${MYOS_NAME}"

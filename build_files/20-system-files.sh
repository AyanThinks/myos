#!/usr/bin/bash
source "$CTX/build_files/lib.sh"

log "Copying system_files into /"
cp -a "$CTX/system_files/." /
chmod 0755 /usr/libexec/myos/*.sh

# Keep config lists inside the image for the first-boot scripts.
install -d /usr/share/myos
cp "$CTX/config/flatpaks.txt" "$CTX/config/flatpaks-optional.txt" /usr/share/myos/

# Resolve @MYOS_NAME@ / @MYOS_ID@ / @MYOS_TAGLINE@ tokens from config/os.env.
TARGETS=(/etc/dconf /etc/xdg /usr/share/myos /usr/share/plymouth/themes/myos
         /usr/share/ublue-os/just/60-myos.just /usr/share/gnome-background-properties
         /usr/libexec/myos /usr/lib/systemd/system/myos-firstboot.service
         /usr/share/themes/MyOS)
while IFS= read -r f; do
    sed -i -e "s|@MYOS_NAME@|${MYOS_NAME}|g" -e "s|@MYOS_ID@|${MYOS_ID}|g" \
           -e "s|@MYOS_TAGLINE@|${MYOS_TAGLINE}|g" "$f"
done < <(grep -rIl '@MYOS_' "${TARGETS[@]}" 2>/dev/null || true)

# Register our ujust recipes with Bazzite's main justfile.
JF=/usr/share/ublue-os/justfile
if [ -f "$JF" ] && ! grep -q '60-myos.just' "$JF"; then
    echo 'import "/usr/share/ublue-os/just/60-myos.just"' >> "$JF"
fi

# System-wide Brave default (ignored harmlessly until the Flatpak is installed).
log "System files installed"

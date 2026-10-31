#!/usr/bin/bash
# os-release, logo, wallpapers (rendered from original SVG artwork), Plymouth.
source "$CTX/build_files/lib.sh"

# --- os-release -----------------------------------------------------------
OSR=/usr/lib/os-release
sed -i -e "s|^NAME=.*|NAME=\"${MYOS_NAME}\"|" \
       -e "s|^PRETTY_NAME=.*|PRETTY_NAME=\"${MYOS_NAME} (Bazzite-based)\"|" \
       -e "s|^HOME_URL=.*|HOME_URL=\"${MYOS_URL}\"|" "$OSR"
grep -q '^LOGO=' "$OSR" && sed -i "s|^LOGO=.*|LOGO=${MYOS_ID}-logo|" "$OSR" || echo "LOGO=${MYOS_ID}-logo" >> "$OSR"
{ echo "MYOS_ID=${MYOS_ID}"; echo "MYOS_BASE=bazzite"; } >> "$OSR"
# ID / ID_LIKE / VARIANT_ID are intentionally untouched: Bazzite tooling keys off them.

# --- logo -----------------------------------------------------------------
install -d /usr/share/pixmaps /usr/share/icons/hicolor/scalable/apps /usr/share/backgrounds/"$MYOS_ID"
cp "$CTX/artwork/logo.svg" "/usr/share/pixmaps/${MYOS_ID}-logo.svg"
cp "$CTX/artwork/logo.svg" "/usr/share/icons/hicolor/scalable/apps/${MYOS_ID}-logo.svg"
rsvg-convert -w 512 -h 512 "$CTX/artwork/logo.svg" -o "/usr/share/pixmaps/${MYOS_ID}-logo.png"
# The dconf/GDM/XML files reference /usr/share/pixmaps/myos-logo.* and /usr/share/backgrounds/myos/*;
# keep those stable names even when MYOS_ID changes.
if [ "$MYOS_ID" != "myos" ]; then
    ln -sf "${MYOS_ID}-logo.svg" /usr/share/pixmaps/myos-logo.svg
    ln -sf "${MYOS_ID}-logo.png" /usr/share/pixmaps/myos-logo.png
    ln -sfn "$MYOS_ID" /usr/share/backgrounds/myos
fi

# --- wallpapers -----------------------------------------------------------
for v in light dark; do
    cp "$CTX/artwork/wallpaper-$v.svg" "/usr/share/backgrounds/${MYOS_ID}/myos-$v.svg"
    rsvg-convert -w 3840 -h 2160 "$CTX/artwork/wallpaper-$v.svg" -o "/usr/share/backgrounds/${MYOS_ID}/myos-$v.png"
done

# --- Plymouth boot splash -------------------------------------------------
PLY=/usr/share/plymouth/themes/myos
rsvg-convert -w 192 -h 192 "$CTX/artwork/logo.svg" -o "$PLY/logo.png"
install -d /etc/plymouth
cat > /etc/plymouth/plymouthd.conf <<PLYEOF
[Daemon]
Theme=myos
ShowDelay=0
DeviceTimeout=8
PLYEOF
log "Branding applied for ${MYOS_NAME}"

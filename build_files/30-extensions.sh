#!/usr/bin/bash
# Installs GNOME Shell extensions system-wide from extensions.gnome.org,
# picking the build that matches the GNOME Shell version in the base image.
source "$CTX/build_files/lib.sh"

EXT_DIR=/usr/share/gnome-shell/extensions
SHELL_VER="$(gnome-shell --version | grep -oE '[0-9]+' | head -n1)"
log "GNOME Shell major version: ${SHELL_VER}"
install -d "$EXT_DIR" /usr/share/myos
REPORT=/usr/share/myos/extensions-installed.txt
: > "$REPORT"
missing=0
tmp="$(mktemp -d)"

while IFS= read -r uuid; do
    if [ -f "$EXT_DIR/$uuid/metadata.json" ]; then
        log "present in base: $uuid"; echo "present  $uuid" >> "$REPORT"; continue
    fi
    info="$(curl -fsSL --retry 5 --retry-delay 3 \
        "https://extensions.gnome.org/extension-info/?uuid=${uuid}&shell_version=${SHELL_VER}" 2>/dev/null || true)"
    dl="$(printf '%s' "$info" | python3 -c 'import sys,json
try: print(json.load(sys.stdin).get("download_url",""))
except Exception: print("")' || true)"
    if [ -z "$dl" ]; then
        warn "no build of $uuid for GNOME $SHELL_VER on extensions.gnome.org"
        echo "MISSING  $uuid (GNOME $SHELL_VER)" >> "$REPORT"; missing=1; continue
    fi
    curl -fsSL --retry 5 --retry-delay 3 -o "$tmp/$uuid.zip" "https://extensions.gnome.org${dl}"
    install -d "$EXT_DIR/$uuid"
    unzip -q -o "$tmp/$uuid.zip" -d "$EXT_DIR/$uuid"
    [ -f "$EXT_DIR/$uuid/metadata.json" ] || { warn "bad zip for $uuid"; echo "MISSING  $uuid (bad zip)" >> "$REPORT"; missing=1; continue; }
    if [ -d "$EXT_DIR/$uuid/schemas" ]; then glib-compile-schemas "$EXT_DIR/$uuid/schemas"; fi
    chmod -R a+rX "$EXT_DIR/$uuid"
    ver="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("version-name") or json.load(open(sys.argv[1])).get("version"))' "$EXT_DIR/$uuid/metadata.json" || echo '?')"
    log "installed $uuid ($ver)"; echo "installed $uuid $ver" >> "$REPORT"
done < <(read_list "$CTX/config/extensions.txt")

rm -rf "$tmp"
if [ "$missing" = 1 ] && [ "${STRICT_EXTENSIONS:-0}" = 1 ]; then
    warn "STRICT_EXTENSIONS=1 and some extensions are missing; failing the build"; exit 1
fi
cat "$REPORT"

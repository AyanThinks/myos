#!/usr/bin/bash
# Per-user idempotent setup. New users already get these from /etc/skel; this also covers
# users created on the original Bazzite install before they switched to @MYOS_NAME@.
set -u
for v in 3.0 4.0; do
    dir="$HOME/.config/gtk-$v"; css="$dir/gtk.css"; src="/usr/share/myos/theme/gtk-$v.css"
    mkdir -p "$dir"
    # Never clobber a user's own stylesheet; only create/refresh our symlink.
    if [ ! -e "$css" ] || [ -L "$css" ]; then ln -sf "$src" "$css"; fi
done
if flatpak info com.brave.Browser >/dev/null 2>&1; then
    xdg-settings set default-web-browser com.brave.Browser.desktop 2>/dev/null || true
fi
exit 0

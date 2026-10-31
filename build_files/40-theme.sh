#!/usr/bin/bash
# Builds the "MyOS" shell theme from the stock GNOME Shell theme + our rounded/glass
# overrides, and wires the libadwaita/GTK CSS into /etc/skel for every new user.
source "$CTX/build_files/lib.sh"

THEME=/usr/share/themes/MyOS
SHELLDIR="$THEME/gnome-shell"
install -d "$SHELLDIR" "$THEME/gtk-3.0" "$THEME/gtk-4.0"

# 1. Extract the stock Shell theme out of its gresource so we can extend it.
RES=/usr/share/gnome-shell/gnome-shell-theme.gresource
[ -f "$RES" ] || { warn "stock shell theme gresource not found"; exit 1; }
for r in $(gresource list "$RES"); do
    rel="${r#/org/gnome/shell/theme/}"
    install -d "$SHELLDIR/$(dirname "$rel")"
    gresource extract "$RES" "$r" > "$SHELLDIR/$rel"
done
[ -f "$SHELLDIR/gnome-shell.css" ] || cp "$SHELLDIR/gnome-shell-dark.css" "$SHELLDIR/gnome-shell.css"

# 2. Append our overrides to every stylesheet variant.
for css in "$SHELLDIR"/*.css; do
    { echo; echo "/* ===== ${MYOS_NAME} overrides ===== */"; cat /usr/share/myos/theme/shell-overrides.css; } >> "$css"
done
log "Shell theme built: $(ls "$SHELLDIR"/*.css | xargs -n1 basename | tr '\n' ' ')"

# 3. GTK3/GTK4 theme = adw-gtk3 + rounded overrides (libadwaita apps use ~/.config/gtk-4.0/gtk.css).
RAD3=/usr/share/myos/theme/gtk-3.0.css
RAD4=/usr/share/myos/theme/gtk-4.0.css
{ echo '@import url("file:///usr/share/themes/adw-gtk3/gtk-3.0/gtk.css");';      cat "$RAD3"; } > "$THEME/gtk-3.0/gtk.css"
{ echo '@import url("file:///usr/share/themes/adw-gtk3-dark/gtk-3.0/gtk.css");'; cat "$RAD3"; } > "$THEME/gtk-3.0/gtk-dark.css"
{ echo '@import url("file:///usr/share/themes/adw-gtk3/gtk-4.0/gtk.css");';      cat "$RAD4"; } > "$THEME/gtk-4.0/gtk.css"
{ echo '@import url("file:///usr/share/themes/adw-gtk3-dark/gtk-4.0/gtk.css");'; cat "$RAD4"; } > "$THEME/gtk-4.0/gtk-dark.css"

# 4. New users: symlink the CSS so image updates restyle everyone automatically.
install -d /etc/skel/.config/gtk-3.0 /etc/skel/.config/gtk-4.0
ln -sf "$RAD3" /etc/skel/.config/gtk-3.0/gtk.css
ln -sf "$RAD4" /etc/skel/.config/gtk-4.0/gtk.css

# 5. Verify fonts/icons made it in (packages are installed with --skip-unavailable).
fc-cache -f >/dev/null 2>&1 || true
fc-list | grep -qi 'Inter' || warn "Inter font not found; falling back to a manual download"
if ! fc-list | grep -qi 'Inter'; then
    t="$(mktemp -d)"
    curl -fsSL --retry 5 -o "$t/inter.zip" https://github.com/rsms/inter/releases/download/v4.0/Inter-4.0.zip
    install -d /usr/share/fonts/inter
    unzip -q -o "$t/inter.zip" 'extras/ttf/*' -d "$t" || unzip -q -o "$t/inter.zip" -d "$t"
    find "$t" -name 'Inter*.ttf' -exec cp {} /usr/share/fonts/inter/ \;
    fc-cache -f; rm -rf "$t"
fi
[ -d /usr/share/icons/Papirus ] || { warn "Papirus icon theme missing"; exit 1; }

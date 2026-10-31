#!/usr/bin/bash
# @MYOS_NAME@ first-boot: add Flathub and install the core apps system-wide (Brave etc.).
# Safe to re-run; exits non-zero if anything failed so systemd retries every 60 s.
set -uo pipefail
STATE=/var/lib/myos
LIST=/usr/share/myos/flatpaks.txt
mkdir -p "$STATE"

# Wait (max ~2 min) for real connectivity; Flathub being reachable is what matters.
for i in $(seq 1 24); do
    curl -fsI --max-time 5 https://dl.flathub.org >/dev/null 2>&1 && break
    sleep 5
done

flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || exit 1

fail=0
while IFS= read -r app; do
    app="${app%%#*}"; app="$(echo "$app" | xargs)"; [ -z "$app" ] && continue
    if flatpak info --system "$app" >/dev/null 2>&1; then echo "already installed: $app"; continue; fi
    echo "installing: $app"
    ok=0
    for attempt in 1 2 3; do
        flatpak install --system --noninteractive -y flathub "$app" && { ok=1; break; }
        sleep 10
    done
    [ "$ok" = 1 ] || { echo "FAILED: $app" >&2; fail=1; }
done < "$LIST"

if [ "$fail" = 0 ]; then
    touch "$STATE/firstboot-done"
    echo "first-boot Flatpak setup complete"
    exit 0
fi
exit 1

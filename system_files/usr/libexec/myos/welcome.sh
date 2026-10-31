#!/usr/bin/bash
# @MYOS_NAME@ welcome wizard: runs once per user at first login.
set -u
MARK="$HOME/.local/share/myos/welcome-done"
[ -e "$MARK" ] && exit 0
mkdir -p "$(dirname "$MARK")"
TITLE="Welcome to @MYOS_NAME@"

/usr/libexec/myos/apply-user-theme.sh

# 1. Wait for the system-wide first-boot Flatpak install (Brave etc.), max 20 minutes.
if [ ! -e /var/lib/myos/firstboot-done ]; then
    (
        for i in $(seq 1 400); do
            [ -e /var/lib/myos/firstboot-done ] && break
            sleep 3
        done
        echo 100
    ) | zenity --progress --pulsate --auto-close --no-cancel --width=420 --title="$TITLE" \
        --text="Installing Brave and your core apps…\nThis needs an internet connection and runs only once." || true
fi
/usr/libexec/myos/apply-user-theme.sh   # now Brave exists -> set as default browser

# 2. Optional extras (per-user Flatpaks, no admin password needed).
mapfile -t LINES < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' /usr/share/myos/flatpaks-optional.txt)
ARGS=()
for l in "${LINES[@]}"; do ARGS+=(FALSE "${l%%|*}" "${l#*|}"); done
if ((${#ARGS[@]})); then
    CHOICE="$(zenity --list --checklist --width=520 --height=420 --title="$TITLE" \
        --text="Pick any extra apps to install now (you can add more later from the app store):" \
        --column="" --column="ID" --column="App" --hide-column=2 --print-column=2 --separator=$'\n' \
        "${ARGS[@]}" || true)"
    if [ -n "$CHOICE" ]; then
        flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        mapfile -t APPS <<<"$CHOICE"
        (
            n=0; total=${#APPS[@]}
            for a in "${APPS[@]}"; do
                echo "# Installing $a…"
                flatpak install --user --noninteractive -y flathub "$a" >/dev/null 2>&1
                n=$((n+1)); echo $((n*100/total))
            done
        ) | zenity --progress --auto-close --no-cancel --width=420 --title="$TITLE" --text="Installing extras…" || true
    fi
fi

zenity --info --width=420 --title="$TITLE" \
    --text="You're all set.\n\n• Super opens the Start menu, Super+S opens Search\n• Dark/Light: quick settings → Dark Style\n• Glass intensity: run  ujust myos-glass clear|regular|tinted" || true
touch "$MARK"

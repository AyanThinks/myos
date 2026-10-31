# @MYOS_NAME@ ujust recipes

# Switch between light and dark appearance (wallpaper follows automatically)
myos-appearance mode="light":
    #!/usr/bin/bash
    set -euo pipefail
    case "{{ mode }}" in
        light) gsettings set org.gnome.desktop.interface color-scheme default ;;
        dark)  gsettings set org.gnome.desktop.interface color-scheme prefer-dark ;;
        *) echo "usage: ujust myos-appearance light|dark"; exit 1 ;;
    esac
    echo "Appearance set to {{ mode }}"

# Liquid-glass intensity, like iOS 27's slider: clear | regular | tinted
myos-glass level="regular":
    #!/usr/bin/bash
    set -euo pipefail
    case "{{ level }}" in
        clear)   sigma=18; bright=0.95; opacity=0.20 ;;
        regular) sigma=35; bright=0.80; opacity=0.45 ;;
        tinted)  sigma=55; bright=0.55; opacity=0.80 ;;
        *) echo "usage: ujust myos-glass clear|regular|tinted"; exit 1 ;;
    esac
    EXT=/usr/share/gnome-shell/extensions
    GSETTINGS_SCHEMA_DIR="$EXT/blur-my-shell@aunetx/schemas" gsettings set org.gnome.shell.extensions.blur-my-shell.panel sigma "$sigma"
    GSETTINGS_SCHEMA_DIR="$EXT/blur-my-shell@aunetx/schemas" gsettings set org.gnome.shell.extensions.blur-my-shell.panel brightness "$bright"
    GSETTINGS_SCHEMA_DIR="$EXT/dash-to-panel@jderose9.github.com/schemas" gsettings set org.gnome.shell.extensions.dash-to-panel trans-panel-opacity "$opacity"
    echo "Glass: {{ level }}"

# Re-apply the rounded GTK CSS to your account (use if you had your own gtk.css before)
myos-apply-theme:
    #!/usr/bin/bash
    set -euo pipefail
    for v in 3.0 4.0; do ln -sf /usr/share/myos/theme/gtk-$v.css "$HOME/.config/gtk-$v/gtk.css" 2>/dev/null || { mkdir -p "$HOME/.config/gtk-$v"; ln -sf /usr/share/myos/theme/gtk-$v.css "$HOME/.config/gtk-$v/gtk.css"; }; done
    echo "Rounded GTK CSS linked. Restart apps to see it."

# Show which GNOME extensions were installed at image build time
myos-extensions-status:
    #!/usr/bin/bash
    cat /usr/share/myos/extensions-installed.txt
    echo; gnome-extensions list --enabled 2>/dev/null || true

# Re-run the system first-boot Flatpak install (Brave etc.)
myos-firstboot-rerun:
    #!/usr/bin/bash
    sudo rm -f /var/lib/myos/firstboot-done
    sudo systemctl restart myos-firstboot.service
    systemctl status myos-firstboot.service --no-pager || true

# Replay the first-login welcome wizard for your account
myos-welcome:
    #!/usr/bin/bash
    rm -f "$HOME/.local/share/myos/welcome-done"
    /usr/libexec/myos/welcome.sh

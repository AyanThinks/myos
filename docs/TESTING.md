# Testing checklist

Run in a VM first (UEFI, 8 GB RAM, 3D accel), then on hardware.

## Build
- [ ] `Build image` workflow green for both matrix entries.
- [ ] Build log shows no `MISSING` lines (also check `/usr/share/myos/extensions-installed.txt` on the system).
- [ ] Package is public on GHCR.

## Boot and branding
- [ ] ISO boots (UEFI; Secure Boot on after MOK enrollment).
- [ ] Plymouth shows the pulsing logo (not the Bazzite splash).
- [ ] `cat /etc/os-release` shows NAME/PRETTY_NAME = your name; `ID` is still `bazzite`.
- [ ] GDM login screen shows your logo and Inter font.

## Installer
- [ ] Disk selection, custom partitioning, and "encrypt my data" all work.
- [ ] Timezone and keyboard pages appear; a user can be created (installer or Initial Setup).
- [ ] Installed system reports `bootc status` image = `ghcr.io/<you>/<id>:latest`.

## Desktop look (log in as a **new** user)
- [ ] Taskbar at the bottom, icons centred, tray/clock/network/volume/battery right, rounded corners.
- [ ] Super opens the ArcMenu Windows 11 layout (pinned, all apps, avatar, power, search). Super+S opens Search Light.
- [ ] Window buttons are on the right; Alt+Tab switches windows; Win+Left/Right snaps; edge drag tiles.
- [ ] Desktop icons (Trash) visible.
- [ ] Blur visible behind taskbar/menus; `ujust myos-glass clear` and `tinted` visibly change it.
- [ ] Nautilus/Settings/Ptyxis windows have ~20 px corners and rounded buttons/popovers (libadwaita CSS applied).
- [ ] Quick Settings → Dark Style flips apps, wallpaper (light↔dark) and icons.
- [ ] Inter is the UI font; Papirus icons are used.

## Apps
- [ ] Welcome wizard appears once, waits for Flatpaks, offers extras.
- [ ] `flatpak list --system` shows Brave, Flatseal, Extension Manager, Bazaar, Resources, ProtonPlus.
- [ ] Brave opens, is the default browser (`xdg-settings get default-web-browser`), and is pinned.
- [ ] Ptyxis pinned; Ctrl+Alt+T opens it.
- [ ] Steam launches, logs in, installs and runs a Proton game; gamescope/MangoHud work (`mangohud glxgears`).
- [ ] Bluetooth pairs a device; a CUPS printer can be added; `fwupdmgr get-devices` runs.
- [ ] `distrobox create` + enter works; Waydroid initialises (`sudo waydroid init`).

## Updates and rollback
- [ ] `ujust update` (or `sudo bootc upgrade`) pulls a newer image of yours.
- [ ] After reboot, `sudo bootc rollback` + reboot returns to the previous image.
- [ ] Rebase from stock Bazzite with `bootc switch` works and the first login applies the theme.

## New-user inheritance
- [ ] `sudo useradd -m probe && sudo passwd probe`, log in as `probe`: full look appears with no manual steps.

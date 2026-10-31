# Troubleshooting

## Build problems
- **`bootc container lint` fails**: read the message; usually stray files in `/var`. Add cleanup to
  `build_files/90-finalize.sh`. As a last resort remove the lint line from the Containerfile.
- **dracut fails**: set `REGENERATE_INITRAMFS=0` in `config/os.env`. The image still boots; the Plymouth theme
  then only shows at shutdown. Bazzite's own initramfs options may differ from ours; if you use LUKS+TPM/FIDO2
  and boot breaks after enabling this, keep it at 0.
- **Out of disk on GitHub runners**: image builds need ~60 GB. Disable the NVIDIA matrix entry or use a larger runner.
- **Package not found**: `10-packages.sh` uses `--skip-unavailable`; check the log for skipped names and fix
  `config/packages.txt`. The build verifies Papirus and the shell theme explicitly.
- **Variant name changed upstream**: Bazzite renames images from time to time. Verify
  `ghcr.io/ublue-os/bazzite-gnome-nvidia-open` still exists and edit the matrix in `build.yml`.

## NVIDIA
- NVIDIA drivers come only from Bazzite's NVIDIA images. Use the `-nvidia` variant (built from
  `bazzite-gnome-nvidia-open`). Do not `bootc switch` a stock NVIDIA Bazzite machine to the non-NVIDIA image.
- Black screen/Wayland issues: select the previous deployment in GRUB, or `sudo bootc rollback`.
- Older GPUs (pre-Turing) need the proprietary (non-open) Bazzite variant: change the base image in the matrix.

## Secure Boot
- Bazzite is signed with the Universal Blue key. After install, at the blue MOK screen choose
  **Enroll MOK → Continue → password `universalblue`**. Or run `ujust enroll-secure-boot-key` before rebooting.
- Your own image is not re-signed for Secure Boot, so it relies on that same key (kernel/modules are Bazzite's).

## Flatpak first-boot timing
- Brave is not there on first login: the system service needs internet. Check
  `systemctl status myos-firstboot` and `journalctl -u myos-firstboot`. It retries every 60 s.
- Force it: `ujust myos-firstboot-rerun`.
- The welcome wizard waits up to 20 minutes for the service, then continues without blocking login.
- Brave only becomes the default browser after the Flatpak exists; the wizard re-applies it, or run
  `xdg-settings set default-web-browser com.brave.Browser.desktop`.

## Extension compatibility after GNOME updates
- Extensions are fetched at build time for the GNOME version in the base image. When Bazzite moves to a new GNOME
  release, an extension may not support it yet. The build prints `MISSING <uuid>` and records it in
  `/usr/share/myos/extensions-installed.txt`. Set `STRICT_EXTENSIONS=1` to make that a hard failure in CI.
- Pin the base tag (`BASE_TAG` in `config/os.env`) to a Bazzite build you tested instead of `stable` if you
  want zero surprises; bump it deliberately.
- Disable a misbehaving extension for a user: `gnome-extensions disable <uuid>`; system-wide, remove it from
  `enabled-extensions` in `00-myos` and rebuild.
- Safe mode: `ujust --choose` → reset, or log in and run `dconf reset -f /org/gnome/shell/`.

## Settings that need on-device verification
Extension settings schemas change between releases. These keys are best-effort and **unknown or invalid keys are
silently ignored** (the extension falls back to its default). If something looks off, configure it in a running
VM and copy the real values:
```
dconf dump /org/gnome/shell/extensions/dash-to-panel/ 
dconf dump /org/gnome/shell/extensions/arcmenu/
dconf dump /org/gnome/shell/extensions/blur-my-shell/
dconf dump /org/gnome/shell/extensions/search-light/
```
Known weak spots: Dash to Panel floating margins (`panel-lengths` + `global-border-radius` + CSS shadow is used;
newer versions may expose dedicated margin keys), ArcMenu `menu-button-icon`/custom icon value names and
pinned-apps format, Search Light shortcut key name, `#dashtopanelMainPanel` CSS selectors.

## Theme not applied
- libadwaita apps read `~/.config/gtk-4.0/gtk.css`. Existing users who already have their own file are not
  overwritten: run `ujust myos-apply-theme` (replaces it with the symlink).
- Flatpak apps need access to that file: `flatpak override --user --filesystem=xdg-config/gtk-4.0:ro`
  (and `gtk-3.0`). Flatseal can do the same.
- Shell theme not loading: confirm the User Themes extension is enabled and `gsettings get
  org.gnome.shell.extensions.user-theme name` returns `'MyOS'`.
- Per-user dconf values from the original Bazzite install override system defaults. Reset with
  `dconf reset -f /org/gnome/desktop/interface/` etc.

## Installer notes
- The stock Anaconda is used (not themed). For a themed live ISO, look at Universal Blue's Titanoboa project
  and its hook mechanism; it can ship a custom installer environment. Not included here because its inputs change often.
- Installed systems track `ghcr.io/<you>/<id>:latest` via the kickstart `%post`; if the package is private,
  updates fail with an auth error. Make it public.
- ISOs are large (8 GB+). Releases cap files at 2 GiB, hence split parts.

## Updates and rollback
- `ujust update` / `sudo bootc upgrade` then reboot. Old deployment stays as rollback.
- Signature errors when switching: either commit `config/signing/cosign.pub` and re-run the build, or switch with
  `sudo bootc switch ghcr.io/<you>/<id>:latest` (unsigned path) if you did not set up signing.

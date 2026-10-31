# MyOS

A Windows-style, frosted-glass, rounded-corner desktop built on **Bazzite GNOME**
(Universal Blue / Fedora Atomic bootc). Everything Bazzite gives you (gaming kernel, GPU drivers,
gamescope, HDR/VRR, Distrobox, Flatpak, `ujust`, atomic updates with rollback) is inherited.

> **Rename it in one place:** `config/os.env` (`MYOS_NAME`, `MYOS_ID`). os-release, Plymouth, GDM,
> the welcome wizard, ujust text, image names, workflows and ISO all follow.

## What you get

| Area | How it is done |
|---|---|
| Base | `ghcr.io/ublue-os/bazzite-gnome:stable` (CI also builds an NVIDIA variant, `myos-nvidia`) |
| Taskbar | Dash to Panel: bottom, centred icons, tray + clock + network/volume/battery on the right |
| Start menu | ArcMenu, Windows 11 layout, opened with **Super** |
| Search | ArcMenu's built-in search box (Super) + Search Light on **Super+S** + GNOME overview search |
| Glass | Blur My Shell + translucent panel; `ujust myos-glass clear\|regular\|tinted` (a slider-like control inspired by iOS 27) |
| Rounded look | Shell theme `MyOS` (stock theme + overrides), libadwaita/GTK4 + GTK3 CSS, 14-28 px radii |
| Light/Dark | Quick Settings → Dark Style (or `ujust myos-appearance dark`); wallpaper switches with it |
| Fonts / icons | Inter, Papirus (open source). No Apple fonts, icons or wallpapers |
| Wallpapers | Original SVG artwork (`artwork/`), rendered to 4K PNG at build time |
| Apps | Steam (from Bazzite), Brave (Flatpak at first boot, default browser, pinned), Ptyxis + Ctrl+Alt+T, Settings, Tweaks, Extension Manager, Flatseal, Bazaar, Files, Resources, Disks, ProtonPlus (GE-Proton) |
| Boot | Plymouth theme `myos`, `quiet splash` kargs, initramfs rebuilt |
| First boot | `myos-firstboot.service` installs Flatpaks; a Zenity welcome wizard offers extras and applies per-user setup |
| Installer | Anaconda ISO via bootc-image-builder, built by GitHub Actions |

### Design reference (iOS 27 / Liquid Glass)
iOS 27 keeps the Liquid Glass language (translucent layers, large radii) and adds a clear-to-tinted
intensity slider, better contrast and more uniform corner radii. This project follows those ideas with
open assets only. It is a lookalike, not a copy: no SF font, Apple icons or Apple wallpapers.

### Two deliberate deviations from the brief
1. **Super opens the Start menu, Super+S opens Search Light.** Both cannot own the bare Super key.
   This matches Windows. ArcMenu's menu already contains a search box.
2. **Installer rebranding is limited.** bootc-image-builder uses the stock Fedora Anaconda UI and offers
   no theming hook, so the installer is *not* rounded/themed. The installed system is. See
   Troubleshooting for the Titanoboa route if you want a themed live installer.

## Repository layout

```
config/            os.env (name), packages, flatpaks, extensions, signing/
build_files/       numbered build steps run inside the image build
system_files/      files copied to / (dconf, theme CSS, Plymouth, systemd, ujust, scripts)
artwork/           logo + light/dark wallpaper SVGs (original)
disk_config/       ISO / qcow2 definitions for bootc-image-builder
.github/workflows/ build.yml (image) and build-iso.yml (ISO + release)
docs/              TESTING.md, TROUBLESHOOTING.md
Containerfile  Justfile
```

## Step by step

### 1. Fork and configure
1. Fork this repo on GitHub (or push it as a new repo).
2. Edit `config/os.env`: name, id, `MYOS_URL`. Commit.
3. *(Optional but recommended)* signing, see `config/signing/README.md`:
   `cosign generate-key-pair`, commit `config/signing/cosign.pub`, then add the contents of `cosign.key`
   as the repo secret **`SIGNING_SECRET`** (Settings → Secrets and variables → Actions). Add
   `SIGNING_PASSWORD` too if you set a password. Never commit `cosign.key`.
4. Settings → Actions → General → Workflow permissions → **Read and write**.

### 2. Run the build
Actions → **Build image** → Run workflow (it also runs on every push and daily). Wait for both matrix
jobs (about 30-60 min the first time). Images land at `ghcr.io/<you>/<MYOS_ID>:latest` and
`ghcr.io/<you>/<MYOS_ID>-nvidia:latest`.

**Make the package public:** your profile → Packages → the image → Package settings → Change visibility →
Public. Installed systems pull updates anonymously; ISO builds and `bootc switch` need this (or a login).

### 3. Build and download the ISO
Actions → **Build ISO** → Run workflow → pick `default` or `nvidia`. Optionally enter a release tag (e.g. `v1`)
to attach the ISO to a GitHub release.
- The full ISO is always available as a **workflow artifact** (14 days).
- GitHub releases cap each file at 2 GiB, so the release gets split parts. Join them:
  `cat MyOS-*.iso.*.part > MyOS.iso && sha256sum -c MyOS-*.iso.sha256`
- Local alternative: `just build && just iso` → `output/bootiso/install.iso`.

### 4. Test in a VM first
```
just build && just qcow2 && just run-vm        # or use virt-manager with the ISO
```
Use UEFI firmware, 4+ CPUs, 8+ GB RAM, 3D acceleration on. Walk through `docs/TESTING.md`.

### 5. Flash and install
- **Fedora Media Writer:** Custom image → pick the `.iso` → write to USB.
- **Ventoy:** copy the `.iso` onto a Ventoy USB; boot, choose it (try GRUB2 mode if the default fails).
- Boot the USB, run the Anaconda installer (disk, partitioning, optional encryption, timezone, keyboard).
  If no user-creation step appears, GNOME Initial Setup creates your user on first boot.
- Secure Boot: Bazzite uses the Universal Blue key. On first boot choose *Enroll MOK* with password `universalblue`.
  Details in `docs/TROUBLESHOOTING.md`.

### 6. Rebase an existing Bazzite install
```bash
sudo bootc switch ghcr.io/<you>/myos:latest          # AMD/Intel
sudo bootc switch ghcr.io/<you>/myos-nvidia:latest   # NVIDIA (use only if you are on the NVIDIA Bazzite image)
systemctl reboot
```
Roll back any time: `sudo bootc rollback && systemctl reboot` (or pick the old entry in GRUB).
Go back to Bazzite: `sudo bootc switch ghcr.io/ublue-os/bazzite-gnome:stable`.
Your home folder and Flatpaks are untouched; the first login runs the welcome wizard and links the rounded CSS.

### Everyday commands
| Command | Purpose |
|---|---|
| `ujust myos-appearance light\|dark` | theme mode |
| `ujust myos-glass clear\|regular\|tinted` | glass intensity |
| `ujust myos-extensions-status` | which extensions made it into the build |
| `ujust myos-firstboot-rerun` | retry the Flatpak install |
| `ujust myos-welcome` | replay the wizard |
| `ujust --choose` | all Bazzite + MyOS recipes |

## Customising
- Packages: `config/packages.txt`. Flatpaks: `config/flatpaks.txt`. Extensions: `config/extensions.txt`.
- Look: `system_files/usr/share/myos/theme/*.css` and `system_files/etc/dconf/db/local.d/00-myos`.
- Best way to tune extension settings: configure them in a running VM, then
  `dconf dump /org/gnome/shell/extensions/ ` and copy the keys into `00-myos`.

## Honest status
This repository was generated and statically validated (shell syntax, YAML/TOML parsing, SVG validity, token
substitution, ujust parsing). **It has not been built or booted by its author.** A full image build needs a
~60 GB machine and network access to Flathub/extensions.gnome.org. Expect to iterate once or twice on the first
CI run, especially on the extension settings listed in `docs/TROUBLESHOOTING.md`.

License: MIT (this repo). Bazzite, GNOME, extensions, Papirus, Inter keep their own licenses.

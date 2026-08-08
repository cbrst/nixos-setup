# NixOS Hyprland Desktop

Reusable NixOS configuration and guarded installer for a Hyprland desktop with
Noctalia, Nemo, AMD graphics, Steam, Flatpak, and the `cbrst/config` dotfiles.

> **Documentation** — see [docs/](docs/). If you are new to Nix/NixOS, start
> with [Getting started](docs/getting-started.md); for everyday commands see
> [Daily workflow](docs/daily-workflow.md).

## Install

### Build the ISO

The ISO embeds this repository at `/root/nixos-config`, including the guarded
installer and its default profile. Build it from an x86_64 Linux machine with
Nix installed:

```sh
./scripts/build-iso.sh
```

The finished image is available at `result/iso/nixos-hyprland-installer-*.iso`.
Boot the image in UEFI mode, including through Ventoy with Secure Boot enabled,
and run:

```sh
sudo /root/nixos-config/scripts/install.sh
```

The ISO contains the locked flake and installation script, so no repository
clone is required. Network access is still required during installation to
download the pinned NixOS desktop closure from the binary cache.

### Using a standard ISO

1. Boot a current NixOS graphical or minimal ISO in **UEFI mode**.
2. Connect to the network and clone this repository.
3. Run the installer from the repository root:

```sh
sudo ./scripts/install.sh
```

The script lists every physical disk with its path, size, model, and serial.
It formats only the disk selected in that list after you type `ERASE /dev/...`.
It refuses a disk that has mounted partitions. It does not mount, partition,
or modify non-selected disks, so an existing Windows disk and a shared data
disk remain untouched.

Default prompts are `cbrst`, `Asgard`, `Europe/Berlin`, and `us`; all can be
changed per installation. The script creates a GPT disk layout with a 1 GiB EFI
partition and Btrfs root subvolumes for `/`, `/home`, `/nix`, and `/var/log`.
It then creates and enrolls Secure Boot keys before the first reboot.

## Secure Boot and Windows

This configuration uses Lanzaboote, systemd-boot, and `sbctl`. The installer
generates a local signing key and enrolls it along with Microsoft's Secure Boot
certificates before rebooting. Secure Boot stays enabled; no first boot with
Secure Boot disabled is required.

Firmware must allow custom Secure Boot keys to be enrolled. On systems that
reject the enrollment, enter firmware setup and enable Setup Mode or clear the
existing platform Secure Boot keys, then rerun the displayed `sbctl enroll-keys
--microsoft` command. This replaces the platform key database with your local
key and Microsoft certificates, allowing both NixOS and Windows to boot.

Windows remains available from the firmware boot menu as `Windows Boot Manager`.
The installer never writes to the Windows disk.

Disable Windows Fast Startup before accessing a Windows NTFS data volume from
Linux. Existing shared disks are deliberately not mounted automatically: add a
label or UUID-based mount only after inspecting the disk and its filesystem.

The generated `hosts/local.nix` and `hosts/hardware-configuration.nix` contain
machine-specific settings. Update the machine after editing configuration with:

```sh
sudo nixos-rebuild switch --flake /etc/nixos#default
```

## Home configuration

The home-manager configuration is managed **standalone**, separately from the
system profile, so the current user can rebuild it without root. The shared,
machine-agnostic module lives in `home/cbrst.nix`; machine-specific values come
from `machine` (see `hosts/local.nix` and `hosts/ghostty.conf`) and deep
overrides from `hosts/home.nix`.

```sh
home-manager switch --flake /etc/nixos#cbrst
```

The `machine` attrset is derived from `hosts/local.nix` (identity) plus
`hosts/ghostty.conf`, whose contents are written to
`~/.config/ghostty/machine` and loaded last by the shared ghostty config.

On a **fresh install**, the installer provisions the home configuration
automatically (as the target user, via `nixos-enter`). If that step fails the
install still succeeds and you run the command once after first login:

```sh
home-manager switch --flake /etc/nixos#cbrst
```

Noctalia provides the bar, launcher, control center, notifications, wallpaper,
lock, idle, tray, and OSD functions. `hyprpaper` remains installed as an
optional fallback and should not be started while Noctalia manages wallpaper.

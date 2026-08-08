# NixOS Hyprland Desktop

Reusable NixOS configuration and guarded installer for a Hyprland desktop with
Noctalia, Nemo, AMD graphics, Steam, Flatpak, and the `cbrst/config` dotfiles.

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

## Secure Boot and Windows

This configuration uses GRUB through the Microsoft-signed shim, so the installed
system boots with Secure Boot enabled without enrolling custom keys or changing
firmware Secure Boot settings. GRUB detects Windows through `os-prober` without
writing to the Windows disk. `Windows Boot Manager` also remains available from
the firmware boot menu.

Disable Windows Fast Startup before accessing a Windows NTFS data volume from
Linux. Existing shared disks are deliberately not mounted automatically: add a
label or UUID-based mount only after inspecting the disk and its filesystem.

The generated `hosts/local.nix` and `hosts/hardware-configuration.nix` contain
machine-specific settings and are ignored by Git. Update the machine after
editing configuration with:

```sh
sudo nixos-rebuild switch --flake /etc/nixos#default
```

Noctalia provides the bar, launcher, control center, notifications, wallpaper,
lock, idle, tray, and OSD functions. `hyprpaper` remains installed as an
optional fallback and should not be started while Noctalia manages wallpaper.

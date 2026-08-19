# Setup

How to get this configuration onto a machine, from building the installer to
your first fully-configured login. It covers two ways to install: using the
custom installer ISO this repo can build, or a stock NixOS ISO.

## Before you start

You need:

- An **x86_64** computer.
- **UEFI** firmware (the installer refuses to run in BIOS mode).
- A disk you are willing to completely erase. The installer only touches the
  disk you explicitly confirm.
- Internet access during installation (packages are downloaded).

## 1. Build the installer ISO

On any machine with Nix and flakes enabled, from this repository:

```sh
./scripts/build-iso.sh
```

This produces `result/iso/nixos-hyprland-installer-<version>.iso`. The ISO
contains the entire flake (system config, home-manager module, installer) at
`/root/nixos-config`, so nothing needs to be cloned on the target machine.

> **Skip this step** if you prefer to use a stock NixOS ISO and clone the repo
> yourself — see [Using a standard ISO](#using-a-standard-iso).

## 2. Boot and install

1. Write the ISO to a USB stick (e.g. `dd if=nixos-hyprland-installer.iso
   of=/dev/sdX bs=4M status=progress`) or use Ventoy.
2. Boot it in **UEFI mode** (enable/keep Secure Boot; the installer enrolls its
   own keys).
3. Run the installer:

```sh
sudo /root/nixos-config/scripts/install.sh
```

(With a stock ISO, clone this repo and run `sudo ./scripts/install.sh` from
its root instead.)

The script walks you through:

1. **Choosing the disk.** It lists every disk with its size/model/serial. You
   type `ERASE /dev/sdX` to confirm — nothing is touched otherwise. A disk with
   mounted partitions is refused.
2. **Identity prompts.** Defaults are `cbrst`, `Asgard`, `asgard`,
   `Europe/Berlin`, `us`. The third prompt is the lowercase host profile. The
   values are written to `hosts/<profile>/local.nix` (the machine-identity half
   of the `machine` specialArg).
3. **Formatting.** It creates a GPT layout with a 1 GiB EFI partition and Btrfs
   subvolumes for `/`, `/home`, `/nix`, `/var/log`.
4. **Secure Boot.** It generates a local signing key and enrolls it together
   with Microsoft's certificates, so both NixOS and Windows can boot with
   Secure Boot enabled. This step happens *before* the system is built because
   Lanzaboote signs boot artifacts during the build.
5. **System install** (`nixos-install --flake …#<profile>`).
6. **Home provisioning.** Because home-manager now runs standalone (see
   [Architecture](architecture.md)), the installer finishes by running
   `home-manager switch` *inside* the freshly installed system, as your user.
   If that step fails (for example due to a network hiccup), the install still
   succeeds and you just run the command once after first login.

## 3. First login

Reboot, pick NixOS from the boot menu (systemd-boot), and log in. The desktop
and your home environment should already be fully configured.

If the installer could not provision your home configuration, do it now:

```sh
home-manager switch --flake /etc/nixos#cbrst@asgard
```

> The target is `<user>@<profile>`, such as `cbrst@asgard`. The user comes from
> `hosts/<profile>/local.nix`; the profile is the host directory name.

## 4. Day-two setup

### Make the repo yours (recommended)

The repository lives at `/etc/nixos`. After install it is owned by `root`. To
edit and commit configs **as your user** (especially the home-manager part,
which you can rebuild without sudo):

```sh
sudo chown -R cbrst:cbrst /etc/nixos
```

Now `git add`/`git commit`/`git push` work without root, and
`home-manager switch` is fully self-service.

### Point the git remote somewhere sensible

The repo ships with its own git history. If you have your own fork/remote of
this machine config, set it up:

```sh
cd /etc/nixos
git remote add origin <your-remote-url>
git push -u origin main
```

### Verify the basics

```sh
nix flake check /etc/nixos        # evaluates everything, catches errors
nix flake show /etc/nixos         # lists host, home, and installer outputs
```

## Secure Boot / Windows notes

- **Key enrollment failure:** if the firmware rejects the custom keys, boot
  into firmware setup, enable Setup Mode (or clear the platform Secure Boot
  keys), then rerun:
  `sudo nixos-enter --root /mnt -c 'sbctl enroll-keys --microsoft'`.
- **Windows**: stays available as `Windows Boot Manager` in the firmware boot
  menu. The installer never writes to a Windows disk. Disable Windows **Fast
  Startup** before reading an NTFS data disk from Linux.
- Shared data disks are deliberately **not** auto-mounted. Add a label/UUID
  based mount in `hosts/<profile>/configuration.nix` after inspecting the disk.

## Troubleshooting during setup

| Symptom | Likely cause / fix |
| --- | --- |
| "boot the NixOS installer in UEFI mode" | You booted in legacy/CSM mode; enable UEFI in firmware and reboot. |
| "run from the NixOS installation ISO" | The script needs `nixos-generate-config`; boot the graphical/minimal NixOS ISO. |
| "refuse to erase it" | A partition on the chosen disk is mounted; unmount or pick another disk. |
| Home provisioning fails at the end | Not fatal — run `home-manager switch --flake /etc/nixos#<user>@<profile>` after login. |

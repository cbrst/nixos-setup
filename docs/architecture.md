# Architecture

This repository manages multiple NixOS machines from one flake. Shared modules
are reused; each host has its own identity, hardware, and optional overrides.

## Repository layout

```
/etc/nixos
├── flake.nix
├── hosts/
│   ├── asgard/                 # one complete host profile
│   │   ├── configuration.nix    # system entry point and module selection
│   │   ├── hardware-configuration.nix
│   │   ├── local.nix            # identity and platform settings
│   │   ├── home.nix             # home-manager overrides
│   │   └── ghostty.conf         # Ghostty overrides
│   └── templates/               # copied by the installer for a new host
├── modules/                     # shared NixOS modules
└── scripts/install.sh
```

Every directory under `hosts/` that contains `local.nix` is a host. The
directory name is its stable flake selector; it need not match the display
hostname. `hosts/templates` is not a host because it intentionally lacks a
`local.nix`.

## Flake outputs

`flake.nix` discovers host directories and creates two outputs for each one:

| Host directory | NixOS output | Home Manager output |
| --- | --- | --- |
| `hosts/asgard` | `nixosConfigurations.asgard` | `homeConfigurations."cbrst@asgard"` |

The Home Manager key contains both user and host, so one user can have separate
home overrides on several machines.

```sh
sudo nixos-rebuild switch --flake /etc/nixos#asgard
home-manager switch --flake /etc/nixos#cbrst@asgard
```

The `machine` special argument is built separately for every host from its
`local.nix` plus the text in `ghostty.conf`. Shared modules receive that value
through `specialArgs` or `extraSpecialArgs`, so they can use settings such as
`machine.hostName` without hardcoding a machine.

## Shared and host-specific settings

Put settings used by all machines in `modules/` or the shared Home Manager
module from the `dotfiles` input. Put settings that differ by machine in the
matching `hosts/<host>/` directory.

| Concern | Location |
| --- | --- |
| Kernel, drivers, mounts, boot entries | `hosts/<host>/hardware-configuration.nix` |
| Hostname, user, timezone, keyboard, platform | `hosts/<host>/local.nix` |
| Shared desktop, base system, gaming defaults | `modules/*.nix` |
| Enable/disable or customize system features for one host | `hosts/<host>/configuration.nix` |
| User-environment overrides for one host | `hosts/<host>/home.nix` |
| Terminal overrides for one host | `hosts/<host>/ghostty.conf` |

## Adding a host manually

1. Copy the template directory: `cp -r hosts/templates hosts/laptop`.
2. Create `hosts/laptop/local.nix` with `user`, `hostName`, `timeZone`,
   `keyMap`, `system`, and optional values such as `noctalia`.
3. Generate or write `hosts/laptop/hardware-configuration.nix` for that
   machine's disks and drivers.
4. Adjust `configuration.nix`, `home.nix`, and `ghostty.conf` as needed.
5. Stage the directory before evaluating: `git add hosts/laptop`.
6. Build it with `sudo nixos-rebuild switch --flake /etc/nixos#laptop` and
   `home-manager switch --flake /etc/nixos#<user>@laptop`.

Nix flakes in a Git checkout do not include untracked files. Staging a new host
is therefore required before its output exists.

## Installer

The installer asks for a host profile after the hostname. It copies the
templates into `hosts/<profile>/` when that directory does not yet exist,
writes the profile's `local.nix` and hardware configuration, stages those
files, and installs `#<profile>`. Existing profile-specific configuration,
home, and Ghostty override files are preserved.

# Documentation

Guides for understanding, setting up, and living with this NixOS
configuration. If you are new to Nix/NixOS, start with **Getting started**
and work your way through.

| Document | What it is for |
| --- | --- |
| [Getting started](getting-started.md) | Nix/NixOS 101 — concepts explained for absolute beginners. Read this first. |
| [Setup](setup.md) | Installing the system: build the ISO, run the installer, first boot, day-two setup. |
| [Daily workflow](daily-workflow.md) | Real-life examples of the commands you will actually run, plus troubleshooting. |
| [Architecture](architecture.md) | How this repository is organized, and how the shared vs. machine-specific split works. |
| [Home-manager migration](home-manager-migration.md) | Instructions for moving the shared home-manager module into the `cbrst/config` dotfiles repo (future work). |

The short version of everything you need day-to-day:

```sh
# Build a change to the *system* (needs sudo):
sudo nixos-rebuild switch --flake /etc/nixos#asgard

# Build a change to *your home environment* (no sudo needed):
home-manager switch --flake /etc/nixos#cbrst@asgard
```

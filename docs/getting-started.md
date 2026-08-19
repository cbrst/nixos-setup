# Getting started with Nix/NixOS

This guide assumes you have **never used Nix or NixOS before**. It explains the
ideas you need so the rest of the documentation and the configuration itself
stop looking like magic.

## What is Nix?

Nix is two things at once:

1. **A programming language.** Configuration in this repository is written in
   it (files ending in `.nix`). It looks a little like JSON mixed with a
   functional programming language. You write *expressions* that describe a
   result, and evaluating them produces a configuration, a package, or a
   whole operating system.
2. **A package manager.** It installs software into an immutable store at
   `/nix/store`. Every package is stored under a name derived from its content,
   e.g. `/nix/store/abc123...-neovim-0.10.0`. If anything about the package
   changes, you get a *new* store path — the old one is untouched. That is why
   Nix can install several versions of the same program side by side and why
   nothing ever "overwrites" something else.

## What is NixOS?

NixOS is a Linux distribution that is **configured declaratively**. Instead of
editing config files in `/etc` by hand and hoping you remember everything you
changed, you describe the *entire* desired system in Nix code. Running a single
command rebuilds the system from that description:

```sh
sudo nixos-rebuild switch --flake /etc/nixos#asgard
```

The old system is not deleted — it becomes a *generation* you can roll back to
(see [Daily workflow](daily-workflow.md)).

## The three layers of this setup

Think of your setup as three stacked layers, each rebuilt separately:

```
┌─────────────────────────────────────────────┐
│ 3. Dotfiles repo (github.com/cbrst/config)  │  App config files (nvim, ghostty,
│    ─ not built, just copied/symlinked       │  zsh, ...) shared across machines.
├─────────────────────────────────────────────┤
│ 2. home-manager  (dotfiles input)           │  Your user's programs, dotfiles,
│    home-manager switch --flake /etc/nixos…  │  services. Rebuilt AS the user,
│                                             │  no sudo.
├─────────────────────────────────────────────┤
│ 1. NixOS system  (hosts/, modules/)         │  Kernel, drivers, display server,
│    sudo nixos-rebuild switch --flake …      │  system services. Rebuilt WITH
│                                             │  sudo.
└─────────────────────────────────────────────┘
```

- **Layer 1** runs as root. It creates the user account and the services your
  desktop needs.
- **Layer 2** belongs to you. It installs programs *into your home profile*
  (like `neovim`, `git`, `ghostty`), symlinks your dotfiles into
  `~/.config/…`, and runs user-level services. This is the part you can modify
  and rebuild without ever typing `sudo`.
- **Layer 3** is a plain git repository of app configuration files that is
  fetched as a "flake input" and symlinked into place by layer 2.

## Key concepts

### Flakes

A **flake** is a standard way to package a Nix project. A directory with a
`flake.nix` file (like `/etc/nixos`) is a flake. It has two parts:

- **`inputs`** — the external dependencies (nixpkgs, home-manager, the dotfiles
  repo, ...). Their exact versions are pinned in `flake.lock`, a lock file
  similar to `package-lock.json` or `Cargo.lock`. This is what makes builds
  reproducible: the same lock file always produces the same result.
- **`outputs`** — what this flake *produces*. Here: one NixOS system per host
  directory (for example `asgard`), the installer ISO, and one home
  configuration per user/host pair (for example `cbrst@asgard`).

### nixpkgs

The central package repository for Nix. It contains tens of thousands of
packages and also the NixOS module system. You never `apt install` anything;
instead you add a package name to a list in your config and rebuild.

### `specialArgs` (how `machine` reaches the configs)

The flake passes values into configurations. For each host directory, it builds
a `machine` attribute set from `hosts/<host>/local.nix` and
`hosts/<host>/ghostty.conf`, then injects it via `specialArgs`. Any module can
then declare it in its function
header:

```nix
{ machine, ... }:
{
  networking.hostName = machine.hostName;
}
```

This is how the *same* shared code can behave differently on each machine.

### Generations

Every `nixos-rebuild switch` (and every `home-manager switch`) creates a new
**generation** — a complete snapshot of that configuration. You can:

- switch back to an older generation,
- boot an older system from the boot menu,
- delete old generations to reclaim disk space.

Rolling back is a core safety net: a broken config change is never fatal,
because the previous generation is still there.

### The Nix language (the bare minimum)

You will mostly be *editing* configs, not writing language libraries, so you
only need to recognise a few forms:

| Syntax | Meaning | Example |
| --- | --- | --- |
| `{ a = 1; b = "x"; }` | Attribute set (like a JSON object / dictionary) | `{ user = "cbrst"; }` |
| `[ 1 2 3 ]` | List | `[ "wheel" "video" ]` |
| `key = value;` | Bindings (note the semicolons) | `networking.hostName = "Asgard";` |
| `with pkgs; [ neovim git ]` | `with` unpacks `pkgs` so names resolve | shorthand for `pkgs.neovim` |
| `machine.ghostty or ""` | Field access with a default if missing | read `machine.ghostty`, or `""` |
| `lib.mkIf cond { … }` | Only apply this block if `cond` is true | enable Linux-only features |
| `import ./file.nix` | Load another file as a value | split config into modules |

The `{ config, pkgs, lib, inputs, machine, ... }: { ... }` header of a module
just declares which parts of the world that module wants access to. `config` is
the final merged configuration, `pkgs` the package set, `lib` a utility
library, `inputs` the flake inputs, and `machine` our per-machine data.

## The two rebuild commands

```sh
# System changes (root). Rebuild everything at layer 1.
sudo nixos-rebuild switch --flake /etc/nixos#asgard

# Home changes (your user). Rebuild layer 2.
home-manager switch --flake /etc/nixos#cbrst@asgard
```

You only need the command for the layer you actually changed. A change to the
shared home module or `hosts/asgard/ghostty.conf` needs only `home-manager
switch`. A change to `modules/*.nix` or `hosts/asgard/configuration.nix` needs
`nixos-rebuild switch`.

> **Rule of thumb:** If you changed something about *your user*, run
> `home-manager switch`. If you changed something about the *machine*, run
> `nixos-rebuild switch`. Most daily edits are home edits.

## Where to go next

- [Setup](setup.md) — install the whole thing on a machine.
- [Daily workflow](daily-workflow.md) — the concrete commands for everyday life.
- [Architecture](architecture.md) — exactly which file controls what.

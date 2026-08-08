# Daily workflow

Real-life examples of working with this NixOS setup. Each example starts from
the phrase "I want to …" and shows exactly what to edit and which command to
run. Read [Getting started](getting-started.md) first if the commands below
look foreign.

## Cheat sheet

```sh
# Your two commands
sudo nixos-rebuild switch --flake /etc/nixos#default   # system changes (root)
home-manager switch --flake /etc/nixos#cbrst           # home changes (your user)

# Inspect / verify
nix flake show /etc/nixos       # what this flake can build
nix flake check /etc/nixos      # check the configs for errors
home-manager generations        # list your home generations
sudo nixos-rebuild list-generations --flake /etc/nixos

# Update pinned inputs, then rebuild
nix flake update /etc/nixos
```

---

## "I want to install a new program for my user"

Programs in `home/cbrst.nix` under `home.packages` are available to **your
user** (no `sudo` needed to use them).

1. Open `/etc/nixos/home/cbrst.nix`.
2. Add the package name to the list, e.g. `htop`:

   ```nix
   home.packages = with pkgs; [
     bat
     eza
     htop              # <-- new
     ...
   ];
   ```

3. Rebuild:

   ```sh
   home-manager switch --flake /etc/nixos#cbrst
   ```

Done. The program appears in your PATH. To find out if a package exists and
its exact attribute name:

```sh
nix search nixpkgs htop
```

> If the package needs proprietary licenses (like `jetbrains.webstorm`), it
> still works: `allowUnfree` is already enabled in `flake.nix`.

## "I want to install a program system-wide"

Some things belong to the *system*: a daemon, a package every user should
have, or a tool you want available even before logging in. Add it in a module
under `environment.systemPackages` (e.g. `modules/base.nix`), then:

```sh
sudo nixos-rebuild switch --flake /etc/nixos#default
```

**When in doubt, prefer `home.packages`** — it needs no `sudo` to rebuild and
stays scoped to you.

## "I want to change my Ghostty settings on this machine only"

Ghostty's config is split: the shared parts come from the dotfiles repo, and a
**machine-specific override** lives in `/etc/nixos/hosts/ghostty.conf`. That
file is loaded last by Ghostty, so anything in it wins.

Example — a bigger font on this machine's high-DPI display:

```ini
font-size = 14
background-opacity = 0.9
```

Then:

```sh
home-manager switch --flake /etc/nixos#cbrst
```

The contents of `hosts/ghostty.conf` become `~/.config/ghostty/machine`. You
can see it took effect with `ghostty +list-fonts` or simply by opening a new
terminal.

> Changes to the *shared* Ghostty config happen in the **dotfiles repo**
> (`github.com/cbrst/config`, directory `ghostty/`), not in this one.

## "I want to add or change my dotfiles"

Dotfiles (nvim, zsh, tmux, …) are symlinked into `~/.config` from the
`github.com/cbrst/config` repo by `home/cbrst.nix`. Editing them is a normal
git workflow in *that* repo:

```sh
cd ~/path/to/cbrst/config   # wherever you cloned it
# edit e.g. nvim/…
git add -A && git commit -m "tweak nvim"
git push
```

Then pull the new commit into the flake and re-link:

```sh
nix flake update /etc/nixos    # updates the dotfiles input (and everything else)
home-manager switch --flake /etc/nixos#cbrst
```

## "I made a mistake and want to go back"

Because every switch creates a generation, going back is easy and safe.

- **System:** `sudo nixos-rebuild switch --rollback --flake /etc/nixos` — or,
  if the system doesn't even boot, pick an older generation from the
  systemd-boot menu at startup.
- **Home:** `home-manager generations` to list them, then
  `home-manager switch --flake /etc/nixos#cbrst` after reverting the file, or
  `nix profile history` / `nix profile rollback` if you use the nix profile.

The old generations remain on disk until you garbage-collect them (next
section).

## "My disk is filling up"

Nix keeps every generation and every old package in `/nix/store`. Clean up old
stuff:

```sh
# Remove generations older than 7 days, then delete unreferenced store paths
sudo nix-collect-garbage --delete-older-than 7d
sudo nix-collect-garbage -d    # delete ALL old generations (careful)
```

`home-manager` has its own: `home-manager expire-generations 7d`.

## "I want to update everything (nixpkgs, home-manager, ghostty, dotfiles)"

```sh
nix flake update /etc/nixos     # refresh flake.lock from the remote repos
sudo nixos-rebuild switch --flake /etc/nixos#default
home-manager switch --flake /etc/nixos#cbrst
```

`flake.lock` is the git-tracked record of what you updated — commit it so the
next machine can reproduce the same versions. To update just one input:
`nix flake update /etc/nixos home-manager`.

> Updating is the moment things can break. If a rebuild fails, `nix flake
> check` will usually point at the offending option, and the previous
> generation is one rollback away.

## "I want to check my configs before switching"

Nix will not let you apply a broken config, but you can catch errors faster:

```sh
nix flake check /etc/nixos
```

It evaluates every output (system, home, ISO) and reports missing options,
type errors, etc. — without installing anything.

## "I want to see what's actually going to change"

```sh
sudo nixos-rebuild build --flake /etc/nixos#default   # builds, does not switch
```

And to review what a switch would change before applying, run
`nixos-rebuild dry-build` (older NixOS releases) or compare store paths.

---

## Troubleshooting

### `home-manager switch` fails with "Existing file '~/.config/ghostty/…' would be clobbered" or a read-only filesystem error

This happens exactly once, when migrating from an older layout where
`~/.config/ghostty` was a single symlink into the read-only Nix store. The
old link must be removed before the new per-file links can be created:

```sh
rm ~/.config/ghostty      # it's a store symlink, safe to remove
home-manager switch --flake /etc/nixos#cbrst
```

### `The option 'programs.noctalia' does not exist`

Noctalia (the Hyprland shell) is Linux-only and opt-in via `machine.noctalia`
in `hosts/local.nix`. The option only exists when that field is set. Either
set `noctalia = true` or remove the reference.

### `home-manager: error: … user 'root' does not match`

`home-manager switch` must run as the user named by `hosts/local.nix`
(`cbrst`), not as root. Log in as that user and retry.

### `error: unfree package '…'`

`allowUnfree` is enabled for the whole flake, so this usually means you added
the package under the wrong `pkgs`. It should resolve once you rebuild with the
flake (not `nix-env`/`nix-shell`).

### `nix flake check` complains the git tree is dirty

Flakes ignore untracked files. New config files must be `git add`-ed before
they are part of the flake source. If you add a new file and the flake can't
see it, `git add <file>` and retry.

### I edited a file but "nothing changed" after switching

Make sure you ran the *right* command for the layer you edited
(system vs. home), and that the file is tracked by git (flakes ignore
untracked files).

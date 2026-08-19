# Migrating cbrst/config to home-manager

## Goal

Make `github.com/cbrst/config` the single source of truth for the home-manager
configuration shared across all machines and operating systems (NixOS, other
Linux distros, macOS). Machine-specific values stay in each machine's flake.

The repo remains a plain (non-flake) `flake = false` input; machine flakes
compose its module.

## Design contract

The shared home-manager module lives at `home-manager/default.nix` and:

- has signature `{ config, pkgs, lib, inputs, machine, ... }` where `machine`
  is provided by the consuming machine flake via `extraSpecialArgs` and
  `inputs` carries the flake inputs (ghostty, noctalia, dotfiles);
- is machine-agnostic: no hardcoded paths, no NixOS-only options, no
  unconditional Linux-only features;
- provides defaults for everything and defines the override mechanism:
  1. simple values come from the `machine` attrset;
  2. deep overrides come from a per-machine home-manager module appended by
     the machine flake;
  3. overridable options are declared with `lib.mkDefault`;
- gates Linux-only features with `lib.mkIf pkgs.stdenv.isLinux`.

### `machine` attrset contract (fields optional unless noted)

- `user` (string, required) — home username
- `hostName` (string) — machine identity/logging
- `homeDirectory` (string, optional) — default `/home/<user>` on Linux,
  `/Users/<user>` on macOS
- `terminal` (string, optional) — default `ghostty`
- `sshAuthSock` (string, optional) — default
  `$HOME/.1password/agent.sock`; the macOS 1Password socket path differs
- `ghostty` (string, optional, default "") — machine-specific ghostty
  override text, written to `~/.config/ghostty/machine`
- `noctalia` (bool, optional, default false) — enables the Noctalia home
  module (Hyprland/Linux only)
- `stateVersion` (string, optional)

### Platform gating

Linux-only behind `lib.mkIf pkgs.stdenv.isLinux`:
`systemd.user.services.*` (incl. the `headroom-bootstrap` one-shot),
`fonts.fontconfig`, `gtk`, `xdg.mimeApps`, `NIXOS_OZONE_WL`, the Noctalia
import.

macOS: provide `launchd.agents` equivalents where needed (e.g. the headroom
one-shot); these can be opt-in via `machine` or added by the machine's
override module.

## Deliverables

1. Maintain `home-manager/` as the shared module consumed from the `dotfiles`
   input:
   - `xdg.configFile` mappings for hypr, noctalia, fastfetch, ghostty, lazygit,
     nvim, starship, tmux, wezterm, yt-dlp, zsh (`.zprofile`/`.zshrc`),
     opencode (keep the `lib.replaceStrings` that rewrites the headroom path);
   - the shared `home.packages` list, `home.sessionVariables`,
     `programs.zsh`, `fonts`/`gtk`, and the headroom-bootstrap service.
2. Ghostty handling:
   - keep `"ghostty/config".source`, `"ghostty/keybindings".source`,
     `"ghostty/themes".source` as per-file symlinks (NOT a whole-directory
     copy, so the machine file can coexist);
   - add `"ghostty/machine".text = machine.ghostty or "";` — the shared
     `ghostty/config` already ends with `config-file = ?machine`, so this
     file is the machine-specific override loaded last.
3. Provide `home-manager/example-flake.nix` showing consumption:

   ```nix
    machine = (import ./hosts/<host>/local.nix) // {
      ghostty = builtins.readFile ./hosts/<host>/ghostty.conf;
   };
    homeConfigurations."${machine.user}@<host>" = home-manager.lib.homeManagerConfiguration {
     pkgs = nixpkgs.legacyPackages.<system>;
     extraSpecialArgs = { inherit inputs machine; };
      modules = [ "${inputs.dotfiles}/home-manager/default.nix" ./hosts/<host>/home.nix ];
   };
   ```

4. Update the repo README: document the module, the `machine` contract, and
   that `setup.sh` duties for home-manager-owned modules are being phased out.
5. Remove `setup.sh` handling for modules now owned by home-manager.

## Constraints

- No secrets in the repo; ghostty `theme`/`machine` stay machine-local.
- Follow existing conventions (AGENTS.md).
- Stay compatible with the `home-manager` `release-26.05` branch used by the
  machine flakes.
- Machine-specific overrides belong in each machine's flake, never here.

## Verification

`nix flake check` / `nix eval` of the module from a machine flake, then a full
`home-manager switch --flake /etc/nixos#<user>` on the NixOS box.

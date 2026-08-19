#!/usr/bin/env bash

# Build the bootable installer ISO from this flake on an x86_64 Linux Nix host.
#
# The ISO embeds the entire flake source (system config, home-manager module,
# machine overrides, installer) at /root/nixos-config, so no network clone is
# needed on the target. The installer then installs the selected host profile
# and provisions the home configuration with standalone home-manager.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

command -v nix >/dev/null || {
  printf '%s\n' "error: Nix with flakes enabled is required to build the ISO" >&2
  exit 1
}

exec nix build "${repo_root}#installerIso" --print-build-logs

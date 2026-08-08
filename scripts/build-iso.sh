#!/usr/bin/env bash

# Build the bootable installer ISO from this flake on an x86_64 Linux Nix host.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

command -v nix >/dev/null || {
  printf '%s\n' "error: Nix with flakes enabled is required to build the ISO" >&2
  exit 1
}

exec nix build "${repo_root}#installerIso" --print-build-logs

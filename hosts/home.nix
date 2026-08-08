# Machine-specific home-manager overrides for Asgard.
# Composed after home/cbrst.nix, so it can override anything the shared
# module declares (including its `mkDefault` defaults).
{ inputs, lib, pkgs, ... }:
let
  # Import unstable separately so the NixOS system remains on nixos-26.05.
  unstablePkgs = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  programs.vscode = {
    # Override the shared module's stable package without changing Home Manager's base set.
    package = lib.mkForce unstablePkgs.vscode;
  };
}

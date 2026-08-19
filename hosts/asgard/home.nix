# Per-machine home-manager overrides for Asgard.
{ inputs, lib, pkgs, ... }:
let
  unstablePkgs = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  programs.vscode.package = lib.mkForce unstablePkgs.vscode;
}

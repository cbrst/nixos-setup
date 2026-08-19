# Per-machine home-manager overrides for Asgard.
{ inputs, lib, pkgs, ... }:
let
  unstablePkgs = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  # Override the shared GTK default only for this machine.
  gtk.font.name = "CommitMono";
  # Keep GTK text compact on Asgard's displays.
  gtk.font.size = 10;

  programs.vscode.package = lib.mkForce unstablePkgs.vscode;
}

# Top-level NixOS configuration for this machine. It pulls together the
# reusable modules and the machine-specific values from the `machine`
# specialArg (built in flake.nix from hosts/local.nix).
#
# Note: this file only configures the *system*. Your user's programs, dotfiles
# and home config are managed by home-manager (see homeConfigurations in
# flake.nix) and rebuilt separately with:
#   home-manager switch --flake /etc/nixos#cbrst
{ config, pkgs, lib, inputs, machine, ... }:
{
  imports = [
    ../modules/base.nix
    ../modules/desktop.nix
    ../modules/gaming.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = machine.hostName;
  time.timeZone = machine.timeZone;
  console.keyMap = machine.keyMap;
  services.xserver.xkb.layout = machine.keyMap;

  # The main user account. This only creates the login; their dotfiles and
  # installed CLI tools come from home-manager, which needs this account to
  # exist first.
  users.users.${machine.user} = {
    isNormalUser = true;
    description = machine.user;
    extraGroups = [ "networkmanager" "wheel" "video" "input" ];
    shell = pkgs.zsh;
  };

  system.stateVersion = "26.05";
}

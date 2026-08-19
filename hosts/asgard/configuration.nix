# Top-level NixOS configuration for Asgard. Shared behavior lives in modules/;
# this host directory holds the hardware and per-machine overrides.
{ pkgs, machine, ... }:
{
  imports = [
    ../../modules/base.nix
    ../../modules/desktop.nix
    ../../modules/gaming.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = machine.hostName;
  time.timeZone = machine.timeZone;
  console.keyMap = machine.keyMap;
  services.xserver.xkb.layout = machine.keyMap;

  users.users.${machine.user} = {
    isNormalUser = true;
    description = machine.user;
    extraGroups = [ "networkmanager" "wheel" "video" "input" ];
    shell = pkgs.zsh;
  };

  system.stateVersion = "26.05";
}

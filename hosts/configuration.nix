{ config, pkgs, lib, inputs, ... }:
let
  local = import ./local.nix;
in
{
  imports = [
    ../modules/base.nix
    ../modules/desktop.nix
    ../modules/gaming.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = local.hostName;
  time.timeZone = local.timeZone;
  console.keyMap = local.keyMap;
  services.xserver.xkb.layout = local.keyMap;

  users.users.${local.user} = {
    isNormalUser = true;
    description = local.user;
    extraGroups = [ "networkmanager" "wheel" "video" "input" ];
    shell = pkgs.zsh;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs local; };
    users.${local.user} = import ../home/cbrst.nix;
  };

  system.stateVersion = "26.05";
}

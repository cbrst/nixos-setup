# Builds the bootable installer ISO (nixos-installer in flake.nix). It bundles
# this repository at /root/nixos-config so the installer can be run offline.
{ config, lib, modulesPath, pkgs, self, ... }:
{
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];

  # Bundle the complete flake and the guarded installer so no network clone is needed.
  isoImage.contents = [
    {
      source = self;
      target = "/root/nixos-config";
    }
  ];

  isoImage.isoName = "nixos-niri-installer-${config.system.nixos.version}.iso";
  networking.networkmanager.enable = lib.mkForce true;

  environment.systemPackages = with pkgs; [
    git
    helix
    networkmanager
  ];

  # Display the exact offline installation command on the live console.
  services.getty.helpLine = ''
    This ISO includes the NixOS configuration at /root/nixos-config.
    Start the guarded installer with: sudo /root/nixos-config/scripts/install.sh
  '';

  system.stateVersion = "26.05";
}

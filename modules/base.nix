{ pkgs, lib, ... }:
{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  nixpkgs.config.allowUnfree = true;

  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot.enable = lib.mkForce false;
  };

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  networking.networkmanager.enable = true;
  services.openssh.enable = true;
  programs.zsh.enable = true;
  programs.dconf.enable = true;

  security.polkit.enable = true;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.amdgpu.initrd.enable = true;

  environment.systemPackages = with pkgs; [
    curl
    git
    gnupg
    gptfdisk
    pciutils
    sbctl
    usbutils
    vim
  ];
}

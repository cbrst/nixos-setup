{ pkgs, lib, inputs, machine, ... }:
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
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ machine.user ];
  };
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

  # The home-manager CLI is installed system-wide so the current user can run
  # `home-manager switch` without needing a separate Nix profile. It also makes
  # first-login provisioning during installation (scripts/install.sh) possible.
  environment.systemPackages = with pkgs; [
    curl
    git
    gnupg
    gptfdisk
    pciutils
    sbctl
    usbutils
    vim
    inputs.home-manager.packages.${pkgs.system}.default
  ];
}

{ pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  programs.nm-applet.enable = true;
  security.pam.services.hyprlock = { };
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.regreet}/bin/regreet";
      user = "greeter";
    };
  };
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;
  services.gnome.gnome-keyring.enable = true;
  services.flatpak.enable = true;
  services.printing.enable = true;
  services.upower.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };

  environment.systemPackages = with pkgs; [
    nemo
    nemo-fileroller
    file-roller
    ffmpegthumbnailer
    loupe
    gnome-disk-utility
    gnome-calculator
    gnome-text-editor
    firefox
    hyprpaper
    hyprlock
    hypridle
    hyprpicker
    hyprsunset
    hyprpolkitagent
    wl-clipboard
    grim
    slurp
    swappy
    playerctl
    brightnessctl
    pavucontrol
    libnotify
    noto-fonts
  ];
}

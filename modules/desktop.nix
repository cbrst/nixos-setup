# The Hyprland desktop: display server, greeter, and the system services and
# apps a desktop needs (files, printing, portals, audio). Noctalia, the shell
# on top of Hyprland, is configured via home-manager (programs.noctalia).
{ pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };
  programs.niri.enable = true;
  programs.nm-applet.enable = true;
  programs.regreet = {
    settings = {
      background = {
        path = "${../assets/regreet-background.jpg}";
        fit = "Cover";
      };
      GTK = {
        application_prefer_dark_theme = true;
        theme_name = "Adwaita-dark";
      };
    };
  };
  security.pam.services.hyprlock = { };
  services.accounts-daemon.enable = true;
  services.displayManager.sessionPackages = [ pkgs.hyprland ];
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.cage}/bin/cage -s -- ${pkgs.regreet}/bin/regreet";
      user = "greeter";
    };
  };
  systemd.tmpfiles.rules = [
    "d /var/log/regreet 0755 greeter greeter -"
  ];
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

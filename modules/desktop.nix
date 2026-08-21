# The Niri desktop: display server, greeter, and the system services and apps a
# desktop needs (files, printing, portals, audio). Noctalia is configured via
# home-manager (programs.noctalia).
{ pkgs, machine, ... }:
{
  programs.niri.enable = true;
  programs.nm-applet.enable = true;
  programs.noctalia-greeter = {
    enable = true;
    settings = {
      appearance = {
        theme_mode = "dark";
        wallpaper = {
          path = "${../assets/regreet-background.jpg}";
          fill_mode = "crop";
        };
      };
      keyboard = {
        layout = machine.keyMap;
      };
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
    ];
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };

  environment.systemPackages = with pkgs; [
    cine
    nemo
    nemo-fileroller
    file-roller
    ffmpegthumbnailer
    loupe
    gnome-disk-utility
    gnome-calculator
    gnome-text-editor
    firefox
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

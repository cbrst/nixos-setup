# Gaming support: Steam with Gamescope sessions plus performance helpers.
# Optional on non-gaming machines - drop it from that host's configuration.nix
# `imports` to disable.
{ pkgs, ... }:
{
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };
  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  # Steam needs Xwayland to run in a Wayland compositor
  programs.xwayland.enable = true;

  environment.systemPackages = with pkgs; [
    mangohud
    protonup-qt
    vulkan-tools
    mesa-demos
  ];
}

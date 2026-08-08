# Gaming support: Steam with Gamescope sessions plus performance helpers.
# Optional on non-gaming machines - drop it from hosts/configuration.nix's
# `imports` to disable.
{ pkgs, ... }:
{
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };
  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  environment.systemPackages = with pkgs; [
    mangohud
    protonup-qt
    vulkan-tools
    mesa-demos
  ];
}

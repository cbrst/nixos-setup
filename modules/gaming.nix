# Gaming support: Steam with Gamescope sessions plus performance helpers.
# Optional on non-gaming machines - drop it from that host's configuration.nix
# `imports` to disable.
{ pkgs, ... }:
{
  # enable support for Xbox One controllers
  hardware.xone.enable = true;

  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };
  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  # Steam needs Xwayland to run in a Wayland compositor
  programs.xwayland.enable = true;

  environment.systemPackages = with pkgs; [
    # small steamos-session-select to exit out of a gamescope session
    (writeShellScriptBin "steamos-session-select" ''
      case "''${1:-}" in
        desktop)
          # Steam's "Switch to Desktop" action uses this SteamOS helper.
          exec ${systemd}/bin/loginctl terminate-session "$XDG_SESSION_ID"
          ;;
        *)
          exit 1
          ;;
      esac
    '')

    mangohud
    protonup-qt
    vulkan-tools
    mesa-demos

    # needed for Steam in Niri
    xwayland-satellite
  ];
}

# Shared, machine-agnostic home-manager module. It provides sensible defaults
# for every machine of the user and defines the override mechanism:
#
#  1. Simple per-machine values come from the `machine` specialArg (see
#     hosts/local.nix and hosts/ghostty.conf) and are plugged in below.
#  2. Deep overrides come from the machine's own module (hosts/home.nix),
#     which is composed *after* this one and can override anything here.
#  3. Everything machine-specific is marked with `machine.<field> or <default>`
#     so a machine can opt out by setting the field.
#
# Linux-only features are wrapped in `lib.mkIf pkgs.stdenv.isLinux` so this
# module also evaluates on macOS (where systemd, fontconfig and GTK don't
# exist). Noctalia is Hyprland/Linux-only and therefore opt-in via
# `machine.noctalia`.
{ config, pkgs, lib, inputs, machine, ... }:
let
  dotfiles = inputs.dotfiles;
  isLinux = pkgs.stdenv.isLinux;
  noctalia = machine.noctalia or false;
  noctaliaModule = { lib, ... }: {
    programs.noctalia = {
      enable = true;
      systemd.enable = true;
    };
  };
  opencodeConfig = lib.replaceStrings
    [ "/Users/cbrst/.local/bin/headroom" ]
    [ "${config.home.homeDirectory}/.local/bin/headroom" ]
    (builtins.readFile "${dotfiles}/opencode/opencode.jsonc");
in
{
  imports = lib.optionals noctalia [
    inputs.noctalia.homeModules.default
    noctaliaModule
  ];

  home = {
    username = machine.user;
    homeDirectory = machine.homeDirectory or (
      if isLinux then "/home/${machine.user}" else "/Users/${machine.user}"
    );
    stateVersion = machine.stateVersion or "26.05";
    sessionVariables = {
      EDITOR = "nvim";
      TERMINAL = machine.terminal or "ghostty";
      BROWSER = "firefox";
      SSH_AUTH_SOCK = machine.sshAuthSock or "$HOME/.1password/agent.sock";
    } // lib.optionalAttrs isLinux {
      NIXOS_OZONE_WL = "1";
    };
    packages = with pkgs; [
      bat
      bat-extras.batdiff
      cmake
      eza
      fastfetch
      fd
      ffmpeg
      fzf
      gcc
      gnumake
      go
      jetbrains.webstorm
      jq
      lazygit
      lua
      markdownlint-cli
      neovim
      nodejs
      prettier
      opencode
      pkg-config
      python3
      ripgrep
      rustup
      shellcheck
      shfmt
      starship
      tmux
      unzip
      uv
      libwebp
      wezterm
      yt-dlp
      zoxide
      zsh
      nerd-fonts.jetbrains-mono
      commit-mono
      inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };

  fonts.fontconfig.enable = lib.mkIf isLinux true;

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
    configFile = {
      "hypr".source = "${dotfiles}/hypr";
      "noctalia".source = "${dotfiles}/noctalia";
      "fastfetch".source = "${dotfiles}/fastfetch";
      # Ghostty is split into per-file symlinks instead of copying the whole
      # directory: the shared files come from the dotfiles repo, while
      # `machine` is generated from hosts/ghostty.conf. The shared config
      # already ends with `config-file = ?machine`, so `machine` is loaded
      # last and wins on this machine.
      "ghostty/config".source = "${dotfiles}/ghostty/config";
      "ghostty/keybindings".source = "${dotfiles}/ghostty/keybindings";
      "ghostty/themes".source = "${dotfiles}/ghostty/themes";
      "ghostty/machine".text = machine.ghostty or "";
      "lazygit".source = "${dotfiles}/lazygit";
      "nvim".source = "${dotfiles}/nvim";
      "starship".source = "${dotfiles}/starship";
      "tmux".source = "${dotfiles}/tmux";
      "wezterm".source = "${dotfiles}/wezterm";
      "yt-dlp".source = "${dotfiles}/yt-dlp";
      "zsh/dotfiles.zprofile".source = "${dotfiles}/zsh/.zprofile";
      "zsh/dotfiles.zshrc".source = "${dotfiles}/zsh/.zshrc";
      "opencode/opencode.jsonc".text = opencodeConfig;
    };
    mimeApps.defaultApplications = lib.mkIf isLinux {
      "inode/directory" = [ "nemo.desktop" ];
    };
  };

  programs.zsh = {
    enable = true;
    dotDir = "${config.home.homeDirectory}/.config/zsh";
    loginExtra = ''
      source "$ZDOTDIR/dotfiles.zprofile"
    '';
    initContent = ''
      source "$ZDOTDIR/dotfiles.zshrc"
    '';
  };

  systemd.user.services.headroom-bootstrap = lib.mkIf isLinux {
    Unit = {
      Description = "Install the Headroom CLI used by the OpenCode profile";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Headroom is not packaged in Nixpkgs; uv keeps it out of the system Python.
      ExecStart = "${pkgs.runtimeShell} -c 'if [[ ! -x ${config.home.homeDirectory}/.local/bin/headroom ]]; then ${pkgs.uv}/bin/uv tool install --python 3.13 \"headroom-ai[all]\"; fi; ${config.home.homeDirectory}/.local/bin/headroom install apply --preset persistent-service --providers manual'";
    };
    Install.WantedBy = [ "default.target" ];
  };

  gtk = lib.mkIf isLinux {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    font = {
      name = "Noto Sans";
      size = 11;
    };
  };
}

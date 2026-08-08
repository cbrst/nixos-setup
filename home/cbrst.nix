{ config, pkgs, lib, inputs, local, ... }:
let
  dotfiles = inputs.dotfiles;
  opencodeConfig = lib.replaceStrings
    [ "/Users/cbrst/.local/bin/headroom" ]
    [ "${config.home.homeDirectory}/.local/bin/headroom" ]
    (builtins.readFile "${dotfiles}/opencode/opencode.jsonc");
in
{
  imports = [ inputs.noctalia.homeModules.default ];

  home = {
    username = local.user;
    homeDirectory = "/home/${local.user}";
    stateVersion = "26.05";
    sessionVariables = {
      EDITOR = "nvim";
      TERMINAL = "ghostty";
      BROWSER = "firefox";
      NIXOS_OZONE_WL = "1";
      SSH_AUTH_SOCK = "$HOME/.1password/agent.sock";
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
      inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };

  fonts.fontconfig.enable = true;

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
      "ghostty".source = "${dotfiles}/ghostty";
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
    mimeApps.defaultApplications = {
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

  systemd.user.services.headroom-bootstrap = {
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

  gtk = {
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

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
  };

  # wayland.windowManager.hyprland = {
  #   enable = true;
  #   systemd.enable = false;
  # };
}

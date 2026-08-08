{
  description = "Reusable Hyprland desktop NixOS configuration";

  # Inputs are the external "ingredients" this flake is built from. Their
  # exact revisions are pinned in flake.lock, which is what makes a build
  # reproducible. `inputs.*.nixpkgs.follows` makes several inputs share a
  # single nixpkgs so we don't end up with multiple conflicting copies.
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    ghostty = {
      url = "github:ghostty-org/ghostty";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote.url = "github:nix-community/lanzaboote/v1.1.0";
    noctalia.url = "github:noctalia-dev/noctalia";
    dotfiles = {
      url = "github:cbrst/config";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, lanzaboote, ... }:
  let
    system = "x86_64-linux";

    # Home-manager runs standalone, so it needs its own pkgs set. It mirrors
    # the system's settings (here: allow proprietary software such as
    # JetBrains WebStorm) because it no longer inherits them from the NixOS
    # configuration.
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    # `machine` is the machine-specific data injected into every configuration
    # through `specialArgs`/`extraSpecialArgs`. hosts/local.nix holds identity
    # (user, hostname, ...) and hosts/ghostty.conf the per-machine Ghostty
    # override, which home-manager writes to ~/.config/ghostty/machine.
    machine = (import ./hosts/local.nix) // {
      ghostty = builtins.readFile ./hosts/ghostty.conf;
    };
  in {
    nixosConfigurations = {
      # The main desktop system. Rebuilt with:
      #   sudo nixos-rebuild switch --flake /etc/nixos#default
      default = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs machine; };
        modules = [
          ./hosts/configuration.nix
          lanzaboote.nixosModules.lanzaboote
        ];
      };

      # Minimal configuration used only to build the bootable installer ISO.
      installer = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs self; };
        modules = [ ./modules/installer-iso.nix ];
      };
    };

    # The user's home environment, managed separately from the system. Rebuilt
    # as the user (no sudo) with:
    #   home-manager switch --flake /etc/nixos#cbrst
    homeConfigurations.${machine.user} = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit inputs machine; };
      modules = [
        # Machine-agnostic defaults (shared across all of the user's machines).
        "${inputs.dotfiles}/home-manager/default.nix"
        # Machine-specific overrides (this machine only).
        ./hosts/home.nix
      ];
    };

    packages.x86_64-linux.installerIso = self.nixosConfigurations.installer.config.system.build.isoImage;
  };
}

{
  description = "Reusable Hyprland desktop NixOS configuration";

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

  outputs = inputs@{ self, nixpkgs, home-manager, lanzaboote, ... }: {
    nixosConfigurations = {
      default = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/configuration.nix
          home-manager.nixosModules.default
          lanzaboote.nixosModules.lanzaboote
        ];
      };

      installer = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs self; };
        modules = [ ./modules/installer-iso.nix ];
      };
    };

    packages.x86_64-linux.installerIso = self.nixosConfigurations.installer.config.system.build.isoImage;
  };
}

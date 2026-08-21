{
  description = "Reusable Niri desktop NixOS configuration";

  # Inputs are the external "ingredients" this flake is built from. Their
  # exact revisions are pinned in flake.lock, which is what makes a build
  # reproducible. `inputs.*.nixpkgs.follows` makes several inputs share a
  # single nixpkgs so we don't end up with multiple conflicting copies.
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # Keep fast-moving desktop applications available without changing the base system channel.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
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
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dotfiles = {
      url = "github:cbrst/config";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, lanzaboote, ... }:
  let
    lib = nixpkgs.lib;
    hostNames = builtins.filter (name:
      (builtins.readDir ./hosts).${name} == "directory"
      && builtins.pathExists ./hosts/${name}/local.nix
    ) (builtins.attrNames (builtins.readDir ./hosts));

    mkMachine = host: (import ./hosts/${host}/local.nix) // {
      ghostty = builtins.readFile ./hosts/${host}/ghostty.conf;
    };

    mkPkgs = system: import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    mkNixosConfiguration = host:
      let machine = mkMachine host;
      in nixpkgs.lib.nixosSystem {
        system = machine.system or "x86_64-linux";
        specialArgs = { inherit inputs machine; };
        modules = [
          ./hosts/${host}/configuration.nix
          lanzaboote.nixosModules.lanzaboote
          inputs.noctalia-greeter.nixosModules.default
        ];
      };

    mkHomeConfiguration = host:
      let
        machine = mkMachine host;
        system = machine.system or "x86_64-linux";
      in {
        name = "${machine.user}@${host}";
        value = home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs system;
          extraSpecialArgs = { inherit inputs machine; };
          modules = [
            "${inputs.dotfiles}/home-manager/default.nix"
            ./hosts/${host}/home.nix
          ];
        };
      };
  in {
    nixosConfigurations = lib.genAttrs hostNames mkNixosConfiguration // {
      # Minimal configuration used only to build the bootable installer ISO.
      installer = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs self; };
        modules = [ ./modules/installer-iso.nix ];
      };
    };

    # Standalone home-manager configurations are keyed by user and host so a
    # single user can have different home overrides on several machines.
    homeConfigurations = lib.listToAttrs (map mkHomeConfiguration hostNames);

    packages.x86_64-linux.installerIso = self.nixosConfigurations.installer.config.system.build.isoImage;
  };
}

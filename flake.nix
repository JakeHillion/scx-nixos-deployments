{
  description = "NixOS flake containing host configs for NixOS managed scx machines.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    flake-utils.url = "github:numtide/flake-utils";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self
    , nixpkgs
    , disko
    , flake-utils
    , ...
    }@inputs: {
      nixosConfigurations =
        let
          fqdns = builtins.attrNames (builtins.readDir ./hosts);

          mkHost = fqdn:
            let
              system = builtins.readFile ./hosts/${fqdn}/system;
            in
            nixpkgs.lib.nixosSystem {
              inherit system;
              specialArgs = inputs;
              modules = [
                ./hosts/${fqdn}/default.nix
                ./modules/default.nix

                disko.nixosModules.disko

                ({ config, ... }: {
                  system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
                })
              ];
            };
        in
        nixpkgs.lib.genAttrs fqdns mkHost;
    } // flake-utils.lib.eachDefaultSystem (system: {
      formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
    });
}

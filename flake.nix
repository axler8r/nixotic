{
  description = "Nixotic, the Quixotic NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, stylix, ... }@inputs:
    let
      system = "x86_64-linux";
      
      # Common Home Manager configuration
      homeManagerConfig = {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupCommand = "backup-$(date +%Y%m%d%H%M%S)";
        home-manager.users.axl = import ./home/default.nix;
      };
      
      mkHost = hostPath: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          hostPath
          home-manager.nixosModules.home-manager
          homeManagerConfig
          stylix.nixosModules.stylix
          ./stylix.nix
        ];
      };
    in
    {
      nixosConfigurations = {
        demonstr8r = mkHost ./hosts/demonstr8r/configuration.nix;
        ambul8r = mkHost ./hosts/ambul8r/configuration.nix;
        
        # ML workstation (TODO: configure when ready)
        # infer8r = mkHost ./hosts/infer8r/configuration.nix;
      };
    };
}

# role selects the whole experience: "workstation" = Stylix +
# home/desktop.nix, "server" = no Stylix + home/headless.nix.
# homeConfig overrides the home profile only (e.g. WSL).
{ inputs, self, system }:
let
  inherit (inputs) nixpkgs home-manager stylix disko;
in
{ hostPath, role ? "workstation", homeConfig ? null }:
let
  isWorkstation = role == "workstation";
  home =
    if homeConfig != null then homeConfig
    else if isWorkstation then ../home/desktop.nix
    else ../home/headless.nix;
in
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit inputs; };
  modules = [
    hostPath
    disko.nixosModules.disko
    home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupCommand = "backup-$(date +%Y%m%d%H%M%S)";
      home-manager.extraSpecialArgs = { inherit self; };
      home-manager.users.axl = import home;
    }
  ] ++ nixpkgs.lib.optionals isWorkstation [
    stylix.nixosModules.stylix
    ../stylix.nix
  ];
}

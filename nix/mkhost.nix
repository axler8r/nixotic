# role is the single place a host's role is declared. It selects the system
# role module (profiles/roles/<role>.nix, which imports base.nix), the home
# profile (home/<role>.nix), and Stylix for workstations.
# homeConfig overrides the home profile only (e.g. WSL).
{ inputs, self, system }:
let
  inherit (inputs) nixpkgs home-manager stylix disko;
in
{ hostPath, role ? "workstation", homeConfig ? null }:
assert role == "workstation" || role == "server";
let
  isWorkstation = role == "workstation";
  home =
    if homeConfig != null then homeConfig
    else ../home + "/${role}.nix";
in
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit inputs; };
  modules = [
    hostPath
    (../profiles/roles + "/${role}.nix")
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

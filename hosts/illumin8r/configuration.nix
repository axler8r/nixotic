{ ... }:

{
  imports = [
    ../../profiles/platform/wsl.nix
  ];

  networking.hostName = "illumin8r";

  # Not a workstation, so the docker group does not come from a role module.
  users.users.axl.extraGroups = [ "docker" ];

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      storage-driver = "overlay2";
    };
  };

  system.stateVersion = "25.11";
}

# Shared runtime configuration for ZFS-on-root hosts. Imported by a host's
# configuration.nix alongside the thin disk.nix that imports
# ./zfs-root-disk.nix. Owns everything common to the layout so hosts do not
# repeat it. Host-specific values (hostId, hostName, hostPlatform,
# stateVersion, bootloader) stay in the host's own configuration.nix.
{ ... }:

{
  boot.supportedFilesystems = [ "zfs" "nfs" ];
  boot.zfs.forceImportRoot = false;

  services.zfs = {
    autoScrub.enable = true;
    autoScrub.interval = "monthly";
    trim.enable = true;
  };

  # USERDATA datasets are plain ZFS and auto-mount at boot; own their mount
  # points here (disko creates them root-owned), mirroring the current hosts.
  systemd.tmpfiles.rules = [
    "d /home/axl            0700 axl users - -"
    "d /home/axl/Documents  0700 axl users - -"
    "d /home/axl/Downloads  0700 axl users - -"
    "d /home/axl/Media      0700 axl users - -"
    "d /home/axl/Projects   0700 axl users - -"
    "d /home/axl/Vaults     0700 axl users - -"
  ];
}

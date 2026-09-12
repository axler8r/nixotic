# WSL platform: NixOS-WSL integration. Windows owns the network edge, so
# sshd from the server role is switched off here.
{ inputs, ... }:

{
  imports = [ inputs.nixos-wsl.nixosModules.default ];

  wsl.enable = true;
  wsl.defaultUser = "axl";

  services.openssh.enable = false;
}

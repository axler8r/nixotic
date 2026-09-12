# Headless server role: base.nix plus key-only SSH from first boot.
# Injected by mkHost (role = "server"); hosts do not import it. Platforms
# that do not want sshd (WSL) set services.openssh.enable = false.
{ lib, ... }:

{
  imports = [ ./base.nix ];

  services.openssh = {
    enable = lib.mkDefault true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}

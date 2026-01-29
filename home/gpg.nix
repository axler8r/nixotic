{ config, pkgs, ... }:

{
  programs.gpg = {
    enable = true;
  };

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-gnome3;
    enableSshSupport = false;
    defaultCacheTtl = 3600;      # 1 hour
    maxCacheTtl = 14400;         # 4 hours
  };
}

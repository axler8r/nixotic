# Headless server role: base.nix plus whatever every server needs.
# Injected by mkHost (role = "server"); hosts do not import it.
{ ... }:

{
  imports = [ ./base.nix ];
}

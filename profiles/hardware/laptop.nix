# Laptop form factor: what every portable host wants regardless of vendor.
# Vendor-specific items (GPU driver, PRIME bus IDs, resume device UUID) stay
# in the host's own configuration.nix.
{ ... }:

{
  services.fwupd.enable = true;
}

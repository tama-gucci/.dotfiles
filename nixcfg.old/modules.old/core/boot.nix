{ config, lib, ... }:

with lib;

{
  # Only enable systemd-boot if secure boot is NOT enabled
  # (lanzaboote replaces systemd-boot for secure boot)
  boot.loader = {
    systemd-boot.enable = mkDefault (!config.modules.secureboot.enable);
    efi.canTouchEfiVariables = true;
  };
}

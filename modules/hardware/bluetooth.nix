{ config, lib, pkgs, ... }:

with lib;

{
  # Use custom namespace to avoid conflict with NixOS's hardware.bluetooth
  options.modules.bluetooth.enable = mkEnableOption "Bluetooth support";

  config = mkIf config.modules.bluetooth.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;  # Bluetooth radio on at startup
    };
    
    # Blueman - Bluetooth device manager (tray icon, pairing UI)
    services.blueman.enable = true;
    
    # KDE Bluetooth integration (works with other DEs too)
    environment.systemPackages = [  ];
  };
}

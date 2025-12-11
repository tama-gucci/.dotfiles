{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.secureboot;
in
{
  options.modules.secureboot = {
    enable = mkEnableOption "Secure Boot with Lanzaboote";
    
    pkiBundle = mkOption {
      type = types.str;
      default = "/var/lib/sbctl";
      description = "Path to the Secure Boot PKI bundle (keys and certificates)";
    };
  };

  config = mkIf cfg.enable {
    # Lanzaboote replaces systemd-boot for Secure Boot support
    boot.loader.systemd-boot.enable = mkForce false;
    
    boot.lanzaboote = {
      enable = true;
      pkiBundle = cfg.pkiBundle;
    };
    
    # Install sbctl for managing Secure Boot keys
    environment.systemPackages = [ pkgs.sbctl ];
  };
}

# ═══════════════════════════════════════════════════════════════════════════
# SECURE BOOT (LANZABOOTE)
# ═══════════════════════════════════════════════════════════════════════════
# Secure boot support using lanzaboote
# Usage: Import flake.modules.nixos.secureboot in your configuration
{ ... }:
{
  flake.modules.nixos.secureboot = { pkgs, lib, config, ... }: {
    # ─────────────────────────────────────────────────────────────────────────
    # OPTIONS
    # ─────────────────────────────────────────────────────────────────────────
    options.secureboot = {
      pkiBundle = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/sbctl";
        description = "Path to Secure Boot PKI bundle";
      };
    };
    
    # ─────────────────────────────────────────────────────────────────────────
    # CONFIG
    # ─────────────────────────────────────────────────────────────────────────
    config = {
      # Disable systemd-boot (lanzaboote takes over)
      boot.loader.systemd-boot.enable = lib.mkForce false;
      
      boot.lanzaboote = {
        enable = true;
        pkiBundle = config.secureboot.pkiBundle;
      };
      
      environment.systemPackages = [ pkgs.sbctl ];
    };
  };
}

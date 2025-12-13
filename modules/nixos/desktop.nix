# ═══════════════════════════════════════════════════════════════════════════
# NIXOS DESKTOP MODULE
# ═══════════════════════════════════════════════════════════════════════════
# Configuration specific to desktop computers
# Inherits: pc
# Differences from laptop: no battery, no power saving, more performance
{ config, ... }:
{
  flake.modules.nixos.desktop = { lib, ... }: {
    imports = [ config.flake.modules.nixos.pc ];
    
    # ─────────────────────────────────────────────────────────────────────────
    # POWER (desktop doesn't need power saving)
    # ─────────────────────────────────────────────────────────────────────────
    services.power-profiles-daemon.enable = lib.mkForce false;
    
    # ─────────────────────────────────────────────────────────────────────────
    # PERFORMANCE
    # ─────────────────────────────────────────────────────────────────────────
    # Desktop can use more aggressive settings
    powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
  };
}

# ═══════════════════════════════════════════════════════════════════════════
# NIXOS LAPTOP MODULE
# ═══════════════════════════════════════════════════════════════════════════
# Configuration specific to laptop computers
# Inherits: pc
# Adds: power management, lid switch, battery optimization
{ config, ... }:
{
  flake.modules.nixos.laptop = { lib, ... }: {
    imports = [ config.flake.modules.nixos.pc ];
    
    # ─────────────────────────────────────────────────────────────────────────
    # POWER MANAGEMENT
    # ─────────────────────────────────────────────────────────────────────────
    services.power-profiles-daemon.enable = true;
    
    # Power-saving CPU governor
    powerManagement = {
      enable = true;
      cpuFreqGovernor = lib.mkDefault "powersave";
    };
    
    # ─────────────────────────────────────────────────────────────────────────
    # SUSPEND/HIBERNATE
    # ─────────────────────────────────────────────────────────────────────────
    services.logind = {
      settings.Login = {
        HandleLidSwitch = "suspend-then-hibernate";
        HandleLidSwitchExternalPower = "suspend";
        HandlePowerKey = "suspend-then-hibernate";
        IdleAction = "suspend-then-hibernate";
        IdleActionSec = "15min";
      };
    };
    
    systemd.sleep.extraConfig = ''
      AllowSuspend=yes
      AllowHibernation=yes
      AllowSuspendThenHibernate=yes
      AllowHybridSleep=yes
      HibernateDelaySec=30min
    '';
    
    # ─────────────────────────────────────────────────────────────────────────
    # BATTERY
    # ─────────────────────────────────────────────────────────────────────────
    services.upower = {
      enable = true;
      percentageLow = 15;
      percentageCritical = 5;
      percentageAction = 3;
      criticalPowerAction = "Hibernate";
    };
  };
}

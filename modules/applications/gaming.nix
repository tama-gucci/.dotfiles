# ═══════════════════════════════════════════════════════════════════════════
# GAMING MODULE
# ═══════════════════════════════════════════════════════════════════════════
# Steam and gaming optimizations
{ config, ... }:
let
  meta = config.flake.meta;
in
{
  # ─────────────────────────────────────────────────────────────────────────
  # NAMED MODULE EXPORT
  # ─────────────────────────────────────────────────────────────────────────
  flake.modules.nixos.gaming = { config, pkgs, ... }: {
    # Steam with Proton support
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      gamescopeSession.enable = false;
    };

    # Gamemode for performance optimization
    programs.gamemode = {
      enable = true;
      settings = {
        general = {
          renice = 10;
        };
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 0;
        };
      };
    };

    # Gamescope compositor
    programs.gamescope = {
      enable = false;
      capSysNice = true;
    };

    # Enable 32-bit libraries for games
    hardware.graphics.enable32Bit = true;

    # Gaming packages
    environment.systemPackages = with pkgs; [
      # Launchers
      faugus-launcher
      
      # Proton/Wine
      protonup-qt
      winetricks
      
      # Tools
      mangohud
      gamemode
      
      # Controllers
      sc-controller
      
      # Performance monitoring
      nvtopPackages.full
    ];

    # User gaming packages via home-manager
    home-manager.users.${meta.owner.username} = { pkgs, ... }: {
      # MangoHud configuration
      xdg.configFile."MangoHud/MangoHud.conf".text = ''
        fps
        frametime
        cpu_stats
        gpu_stats
        cpu_temp
        gpu_temp
        ram
        vram
        position=top-left
        font_size=18
        background_alpha=0.4
        round_corners=8
      '';
    };
  };
}


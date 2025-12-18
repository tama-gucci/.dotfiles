# ═══════════════════════════════════════════════════════════════════════════
# NOCTALIA SHELL MODULE
# ═══════════════════════════════════════════════════════════════════════════
# Window-manager agnostic shell with integration for Hyprland and Niri
{ config, inputs, ... }:
let
  meta = config.flake.meta;
in
{
  # ─────────────────────────────────────────────────────────────────────────
  # NAMED MODULE EXPORT
  # ─────────────────────────────────────────────────────────────────────────
  flake.modules.nixos.noctalia = { config, pkgs, ... }: {
    imports = [ inputs.noctalia.nixosModules.noctalia ];

    # Enable Noctalia shell
    programs.noctalia = {
      enable = true;
      
      # Bar (Ags-based)
      bar.enable = true;
      
      # Notifications (Ags-based)
      notifications.enable = true;
      
      # Application launcher
      launcher.enable = true;
      
      # OSD (On-Screen Display)
      osd.enable = true;
      
      # Power menu / session controls
      session.enable = true;
      
      # Screenshot utility
      screenshot.enable = true;
      
      # Clipboard manager
      clipboard.enable = true;
      
      # Wallpaper manager (swww-based)
      wallpaper.enable = true;
      
      # Lock screen
      lockscreen.enable = true;
      
      # Idle management
      idle.enable = true;
    };

    # Additional packages that complement Noctalia
    environment.systemPackages = with pkgs; [
      brightnessctl
      playerctl
      pamixer
      libnotify
    ];

    # Home-manager integration for user-level Noctalia config
    home-manager.users.${meta.owner.username} = { pkgs, ... }: {
      # Noctalia stores user configuration in XDG config
      xdg.configFile = {
        # Theme configuration (can be extended)
        "noctalia/theme.json".text = builtins.toJSON {
          accent = "#89b4fa";
          background = "#1e1e2e";
          foreground = "#cdd6f4";
          border-radius = 12;
          gaps = 10;
        };
      };
    };
  };
}

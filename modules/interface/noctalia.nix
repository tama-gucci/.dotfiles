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
    imports = [ inputs.noctalia.nixosModules.default ];

    # Enable Noctalia shell systemd service
    services.noctalia-shell = {
      enable = true;
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
      imports = [ inputs.noctalia.homeModules.default ];

      # Enable Noctalia shell user configuration
      programs.noctalia-shell = {
        enable = true;

        # Shell settings
        settings = {
          bar = {
            position = "top";
            floating = true;
            backgroundOpacity = 0.95;
          };
          general = {
            animationSpeed = 1.5;
            radiusRatio = 1.2;
          };
          colorSchemes = {
            darkMode = true;
            useWallpaperColors = true;
          };
        };

        # Color configuration (Catppuccin Mocha inspired)
        colors = {
          mPrimary = "#89b4fa";
          mSecondary = "#cba6f7";
          mTertiary = "#f5c2e7";
          mSurface = "#1e1e2e";
          mSurfaceVariant = "#313244";
          mOnSurface = "#cdd6f4";
          mOnSurfaceVariant = "#a6adc8";
          mOutline = "#45475a";
          mShadow = "#000000";
          mError = "#f38ba8";
          mOnError = "#1e1e2e";
          mOnPrimary = "#1e1e2e";
          mOnSecondary = "#1e1e2e";
          mOnTertiary = "#1e1e2e";
        };
      };
    };
  };
}


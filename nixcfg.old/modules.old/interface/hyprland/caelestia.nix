# ═══════════════════════════════════════════════════════════════════════════
# DEPRECATED: This module has been replaced by Noctalia shell
# ═══════════════════════════════════════════════════════════════════════════
#
# Caelestia shell integration has been removed in favor of Noctalia.
# Please update your configuration to use the new noctalia module:
#
#   modules.noctalia = {
#     enable = true;
#     windowManager = "hyprland";  # or "niri"
#     # ... other settings
#   };
#
# This file can be safely deleted.
# ═══════════════════════════════════════════════════════════════════════════
{ config, lib, ... }:

with lib;

{
  options.modules.hyprland.caelestia = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "DEPRECATED: Use modules.noctalia instead";
    };
    
    # Stub options to prevent errors during migration
    wallpaperDir = mkOption { type = types.str; default = ""; };
    showBattery = mkOption { type = types.bool; default = true; };
    transparency = {
      enable = mkOption { type = types.bool; default = false; };
      base = mkOption { type = types.float; default = 0.85; };
    };
  };

  config = mkIf config.modules.hyprland.caelestia.enable {
    warnings = [
      ''
        modules.hyprland.caelestia is DEPRECATED and has been removed.
        
        Please migrate to the new Noctalia module:
        
          modules.noctalia = {
            enable = true;
            windowManager = "hyprland";
            wallpaperDir = "~/Pictures/Wallpapers";
            showBattery = true;
            # ... other settings
          };
        
        Then delete this file: modules/interface/hyprland/caelestia.nix
      ''
    ];
  };
}

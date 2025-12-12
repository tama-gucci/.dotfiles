{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.monitors;
  
  # Type for a single monitor configuration
  monitorType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Monitor name/identifier (e.g., 'eDP-1', 'DP-1', 'HDMI-A-1')";
        example = "eDP-1";
      };
      
      width = mkOption {
        type = types.int;
        default = 1920;
        description = "Horizontal resolution";
        example = 2560;
      };
      
      height = mkOption {
        type = types.int;
        default = 1080;
        description = "Vertical resolution";
        example = 1440;
      };
      
      refreshRate = mkOption {
        type = types.int;
        default = 60;
        description = "Refresh rate in Hz";
        example = 144;
      };
      
      x = mkOption {
        type = types.int;
        default = 0;
        description = "Horizontal position offset";
      };
      
      y = mkOption {
        type = types.int;
        default = 0;
        description = "Vertical position offset";
      };
      
      scale = mkOption {
        type = types.float;
        default = 1.0;
        description = "Display scale factor";
        example = 1.5;
      };
      
      transform = mkOption {
        type = types.enum [ "normal" "90" "180" "270" "flipped" "flipped-90" "flipped-180" "flipped-270" ];
        default = "normal";
        description = "Display rotation/transformation";
      };
      
      vrr = mkOption {
        type = types.ints.between 0 3;
        default = 0;
        description = ''
          Variable Refresh Rate mode:
          0 - off
          1 - on
          2 - fullscreen only
          3 - fullscreen with game content type
        '';
        example = 1;
      };
      
      hdr = mkOption {
        type = types.bool;
        default = false;
        description = "Enable HDR (High Dynamic Range)";
      };
      
      primary = mkOption {
        type = types.bool;
        default = false;
        description = "Set as the primary monitor";
      };
      
      enabled = mkOption {
        type = types.bool;
        default = true;
        description = "Enable or disable this monitor";
      };
    };
  };
  
  # Helper to convert transform to Hyprland format
  hyprlandTransform = transform: {
    "normal" = "0";
    "90" = "1";
    "180" = "2";
    "270" = "3";
    "flipped" = "4";
    "flipped-90" = "5";
    "flipped-180" = "6";
    "flipped-270" = "7";
  }.${transform};
  
  # Helper to convert transform to Niri format
  niriTransform = transform: {
    "normal" = "";
    "90" = "transform \"90\"";
    "180" = "transform \"180\"";
    "270" = "transform \"270\"";
    "flipped" = "transform \"flipped\"";
    "flipped-90" = "transform \"flipped-90\"";
    "flipped-180" = "transform \"flipped-180\"";
    "flipped-270" = "transform \"flipped-270\"";
  }.${transform};
  
  # Generate Hyprland monitor line
  # Format: name,resolution@rate,position,scale[,transform,N][,vrr,N]
  toHyprlandMonitor = mon:
    if mon.enabled then
      let
        base = "${mon.name},${toString mon.width}x${toString mon.height}@${toString mon.refreshRate},${toString mon.x}x${toString mon.y},${toString mon.scale}";
        transformPart = optionalString (mon.transform != "normal") ",transform,${hyprlandTransform mon.transform}";
        vrrPart = optionalString (mon.vrr > 0) ",vrr,${toString mon.vrr}";
      in
        base + transformPart + vrrPart
    else
      "${mon.name},disable";
  
  # Generate Niri output block
  toNiriOutput = mon:
    if mon.enabled then
      ''
        output "${mon.name}" {
            mode "${toString mon.width}x${toString mon.height}@${toString mon.refreshRate}"
            scale ${toString mon.scale}
            position x=${toString mon.x} y=${toString mon.y}
            ${niriTransform mon.transform}
            ${optionalString (mon.vrr > 0) "variable-refresh-rate"}
        }
      ''
    else
      ''
        output "${mon.name}" {
            off
        }
      '';

in
{
  options.modules.monitors = {
    displays = mkOption {
      type = types.listOf monitorType;
      default = [];
      description = "List of monitor configurations";
      example = literalExpression ''
        [
          {
            name = "eDP-1";
            width = 2560;
            height = 1600;
            refreshRate = 120;
            scale = 1.5;
            primary = true;
          }
          {
            name = "HDMI-A-1";
            width = 1920;
            height = 1080;
            refreshRate = 60;
            x = 2560;
            y = 0;
          }
        ]
      '';
    };
    
    # Convenience exports for other modules
    hyprlandConfig = mkOption {
      type = types.listOf types.str;
      readOnly = true;
      default = map toHyprlandMonitor cfg.displays;
      description = "Generated Hyprland monitor configuration lines";
    };
    
    niriConfig = mkOption {
      type = types.str;
      readOnly = true;
      default = concatStringsSep "\n" (map toNiriOutput cfg.displays);
      description = "Generated Niri output configuration blocks";
    };
    
    primaryMonitor = mkOption {
      type = types.nullOr types.str;
      readOnly = true;
      default = 
        let primary = findFirst (m: m.primary) null cfg.displays;
        in if primary != null then primary.name else 
           if cfg.displays != [] then (head cfg.displays).name else null;
      description = "Name of the primary monitor";
    };
    
    hdrEnabled = mkOption {
      type = types.bool;
      readOnly = true;
      default = any (m: m.hdr && m.enabled) cfg.displays;
      description = "Whether any monitor has HDR enabled";
    };
  };
  
  # No direct config here - Hyprland and Niri modules consume the options
  config = {};
}

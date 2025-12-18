# ═══════════════════════════════════════════════════════════════════════════
# MONITORS CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════
# Universal monitor configuration that generates WM-specific configs
{ lib, ... }:
{
  flake.modules.nixos.monitors = { pkgs, lib, config, ... }:
  let
    # ─────────────────────────────────────────────────────────────────────────
    # MONITOR TYPE
    # ─────────────────────────────────────────────────────────────────────────
    monitorType = lib.types.submodule {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "Monitor identifier (e.g., 'HDMI-A-1', 'DP-1')";
        };
        width = lib.mkOption {
          type = lib.types.int;
          default = 1920;
        };
        height = lib.mkOption {
          type = lib.types.int;
          default = 1080;
        };
        refreshRate = lib.mkOption {
          type = lib.types.int;
          default = 60;
        };
        x = lib.mkOption {
          type = lib.types.int;
          default = 0;
        };
        y = lib.mkOption {
          type = lib.types.int;
          default = 0;
        };
        scale = lib.mkOption {
          type = lib.types.float;
          default = 1.0;
        };
        transform = lib.mkOption {
          type = lib.types.enum [ "normal" "90" "180" "270" "flipped" "flipped-90" "flipped-180" "flipped-270" ];
          default = "normal";
        };
        vrr = lib.mkOption {
          type = lib.types.ints.between 0 3;
          default = 0;
          description = "VRR mode: 0=off, 1=on, 2=fullscreen, 3=fullscreen+game";
        };
        hdr = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable HDR (Hyprland only)";
        };
        primary = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        enabled = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
      };
    };
    
    # ─────────────────────────────────────────────────────────────────────────
    # TRANSFORM CONVERTERS
    # ─────────────────────────────────────────────────────────────────────────
    hyprlandTransform = t: {
      "normal" = "0"; "90" = "1"; "180" = "2"; "270" = "3";
      "flipped" = "4"; "flipped-90" = "5"; "flipped-180" = "6"; "flipped-270" = "7";
    }.${t};
    
    niriTransform = t: {
      "normal" = "";
      "90" = ''transform "90"'';
      "180" = ''transform "180"'';
      "270" = ''transform "270"'';
      "flipped" = ''transform "flipped"'';
      "flipped-90" = ''transform "flipped-90"'';
      "flipped-180" = ''transform "flipped-180"'';
      "flipped-270" = ''transform "flipped-270"'';
    }.${t};
    
    # ─────────────────────────────────────────────────────────────────────────
    # CONFIG GENERATORS
    # ─────────────────────────────────────────────────────────────────────────
    toHyprland = mon:
      if mon.enabled then
        let
          base = "${mon.name},${toString mon.width}x${toString mon.height}@${toString mon.refreshRate},${toString mon.x}x${toString mon.y},${toString mon.scale}";
          transform = lib.optionalString (mon.transform != "normal") ",transform,${hyprlandTransform mon.transform}";
          vrr = lib.optionalString (mon.vrr > 0) ",vrr,${toString mon.vrr}";
          hdr = lib.optionalString mon.hdr ",bitdepth,10";
        in base + transform + vrr + hdr
      else "${mon.name},disable";
    
    toNiri = mon:
      if mon.enabled then ''
        output "${mon.name}" {
            mode "${toString mon.width}x${toString mon.height}@${toString mon.refreshRate}"
            scale ${toString mon.scale}
            position x=${toString mon.x} y=${toString mon.y}
            ${niriTransform mon.transform}
            ${lib.optionalString (mon.vrr > 0) "variable-refresh-rate on-demand"}
        }
      '' else ''
        output "${mon.name}" {
            off
        }
      '';
  in
  {
    # ─────────────────────────────────────────────────────────────────────────
    # FLAKE-LEVEL OPTIONS
    # ─────────────────────────────────────────────────────────────────────────
    # These can be accessed by both Hyprland and Niri modules
    options.monitors = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          displays = lib.mkOption {
            type = lib.types.listOf monitorType;
            default = [];
          };
        };
      });
      default = {};
      description = "Monitor configurations per host";
    };
    
    # Export helper functions
    config._module.args.monitorLib = {
      inherit toHyprland toNiri monitorType;
      
      # Get Hyprland config for a display list
      hyprlandConfig = displays: map toHyprland displays;
      
      # Get Niri config for a display list
      niriConfig = displays: lib.concatStringsSep "\n" (map toNiri displays);
      
      # Check if any display has HDR
      hdrEnabled = displays: lib.any (m: m.hdr && m.enabled) displays;
      
      # Check if any display has VRR
      vrrEnabled = displays: lib.any (m: m.vrr > 0 && m.enabled) displays;
      
      # Get primary monitor name
      primaryMonitor = displays:
        let primary = lib.findFirst (m: m.primary) null displays;
        in if primary != null then primary.name
           else if displays != [] then (lib.head displays).name
           else null;
    };
  };
}


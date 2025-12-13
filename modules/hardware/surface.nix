# ═══════════════════════════════════════════════════════════════════════════
# MICROSOFT SURFACE HARDWARE MODULE
# ═══════════════════════════════════════════════════════════════════════════
# Surface device support via nixos-hardware + linux-surface patches
# Supports: Surface Laptop Studio, Surface Pro (Intel), Surface Laptop (AMD)
#
# Key components from linux-surface wiki:
# - Patched kernel with Surface Aggregator Module (SAM)
# - IPTSD for touchscreen/stylus support  
# - surface-control for device management
# - Proper power management and thermals
{ config, inputs, ... }:
{
  flake.modules.nixos.surface = { config, lib, pkgs, ... }:
  let
    cfg = config.surface;
  in
  {
    # ─────────────────────────────────────────────────────────────────────────
    # OPTIONS
    # ─────────────────────────────────────────────────────────────────────────
    options.surface = {
      model = lib.mkOption {
        type = lib.types.enum [ 
          "laptop-studio"     # Surface Laptop Studio 1/2 (Intel + NVIDIA)
          "pro-intel"         # Surface Pro (Intel-based)
          "laptop-amd"        # Surface Laptop (AMD-based)
          "go"                # Surface Go
        ];
        description = "Surface device model for hardware-specific optimizations";
      };
      
      kernelVersion = lib.mkOption {
        type = lib.types.enum [ "longterm" "stable" ];
        default = "longterm";
        description = "Linux-surface kernel version: longterm (LTS) or stable";
      };
      
      touchscreen = {
        enable = lib.mkEnableOption "IPTSD touchscreen daemon" // { default = true; };
      };
    };
    
    # ─────────────────────────────────────────────────────────────────────────
    # CONFIG
    # ─────────────────────────────────────────────────────────────────────────
    config = {
      # Import nixos-hardware Surface modules based on model
      imports = 
        # Common Surface module (patched kernel, firmware, etc.)
        [ inputs.nixos-hardware.nixosModules.microsoft-surface-common ]
        
        # Model-specific imports
        ++ lib.optionals (cfg.model == "laptop-studio") [
          # Laptop Studio uses Intel CPU (handled by parent laptop module)
          # NVIDIA GPU is handled by the nvidia module with Prime
          inputs.nixos-hardware.nixosModules.common-pc
          inputs.nixos-hardware.nixosModules.common-pc-ssd
          inputs.nixos-hardware.nixosModules.common-cpu-intel
        ]
        ++ lib.optionals (cfg.model == "pro-intel") [
          inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel
        ]
        ++ lib.optionals (cfg.model == "laptop-amd") [
          inputs.nixos-hardware.nixosModules.microsoft-surface-laptop-amd
        ]
        ++ lib.optionals (cfg.model == "go") [
          inputs.nixos-hardware.nixosModules.microsoft-surface-go
        ];
      
      # Set kernel version preference
      hardware.microsoft-surface.kernelVersion = cfg.kernelVersion;
      
      # ─────────────────────────────────────────────────────────────────────
      # TOUCHSCREEN & STYLUS (IPTSD)
      # ─────────────────────────────────────────────────────────────────────
      # IPTSD = Intel Precise Touch & Stylus Daemon
      # Required for touchscreen and pen input on most Surface devices
      services.iptsd.enable = lib.mkDefault cfg.touchscreen.enable;
      
      # ─────────────────────────────────────────────────────────────────────
      # SURFACE CONTROL UTILITY
      # ─────────────────────────────────────────────────────────────────────
      # CLI tool for controlling Surface-specific features:
      # - Performance profiles, battery limits, keyboard backlight
      # - DTX (clipboard detach) for Book/Laptop Studio devices
      environment.systemPackages = [ pkgs.surface-control ];
      
      # ─────────────────────────────────────────────────────────────────────
      # THERMAL MANAGEMENT
      # ─────────────────────────────────────────────────────────────────────
      services.thermald.enable = lib.mkDefault true;
      
      # ─────────────────────────────────────────────────────────────────────
      # POWER MANAGEMENT (Surface-specific)
      # ─────────────────────────────────────────────────────────────────────
      # Deep sleep for better battery (S0ix / Modern Standby)
      boot.kernelParams = lib.mkDefault [ "mem_sleep_default=deep" ];
      
      # TLP can cause issues with Surface devices per nixos-hardware docs
      services.tlp.enable = lib.mkForce false;
      
      # ─────────────────────────────────────────────────────────────────────
      # FIRMWARE
      # ─────────────────────────────────────────────────────────────────────
      hardware.enableRedistributableFirmware = lib.mkDefault true;
      
      # IIO sensors (accelerometer, gyro for screen rotation)
      hardware.sensor.iio.enable = lib.mkDefault true;
      
      # ─────────────────────────────────────────────────────────────────────
      # LAPTOP STUDIO SPECIFIC
      # ─────────────────────────────────────────────────────────────────────
      # The Laptop Studio has a unique hinge that allows "studio mode"
      # and a clipboard that can be pulled forward
      boot.kernelModules = lib.mkIf (cfg.model == "laptop-studio") [
        "surface_aggregator"
        "surface_aggregator_registry"
        "surface_hid"
        "surface_kbd"
        "hid_multitouch"
      ];
      
      # Screen rotation support (for studio/tent modes)
      services.libinput.enable = lib.mkDefault true;
    };
  };
}

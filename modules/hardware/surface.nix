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
#
# Known issues addressed (per linux-surface wiki):
# - Touchpad palm detection false positives
# - Keyboard/touchpad disabled in slate mode on Wayland
# - Audio quality issues at 44.1kHz
# - NVIDIA GPU 10W power limit
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
          "laptop-studio-2"   # Surface Laptop Studio 2 (additional touchpad fixes)
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
      
      # Quirks from linux-surface wiki
      quirks = {
        touchpadPalmDetection = lib.mkEnableOption "touchpad palm detection quirk (SLS1)" // {
          default = cfg.model == "laptop-studio";
        };
        
        slateModePeripherals = lib.mkEnableOption "allow keyboard/touchpad in slate mode" // {
          default = cfg.model == "laptop-studio" || cfg.model == "laptop-studio-2";
        };
        
        iptsdTouchpadCalibration = lib.mkEnableOption "IPTSD touchpad calibration (SLS2)" // {
          default = cfg.model == "laptop-studio-2";
        };
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
        ++ lib.optionals (cfg.model == "laptop-studio" || cfg.model == "laptop-studio-2") [
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
      
      # IPTSD touchpad calibration for Surface Laptop Studio 2
      # Fixes touchpad acting like touchscreen (1-to-1 mapping issue)
      # See: https://github.com/linux-surface/linux-surface/wiki/Surface-Laptop-Studio-2
      environment.etc."iptsd.d/50-touchpad.conf" = lib.mkIf cfg.quirks.iptsdTouchpadCalibration {
        text = ''
          [Contacts]
          ActivationThreshold = 40
          DeactivationThreshold = 36
          OrientationThresholdMax = 15
        '';
      };
      
      # ─────────────────────────────────────────────────────────────────────
      # LIBINPUT QUIRKS (Surface Laptop Studio specific)
      # ─────────────────────────────────────────────────────────────────────
      # Quirks for touchpad and tablet mode issues
      # See: https://github.com/linux-surface/linux-surface/wiki/Surface-Laptop-Studio
      environment.etc."libinput/local-overrides.quirks".text = lib.mkMerge [
        # Touchpad palm detection quirk for SLS1
        # Fixes: cursor not moving, cursor stops when selecting text/dragging
        (lib.mkIf cfg.quirks.touchpadPalmDetection ''
          [Microsoft Surface Laptop Studio Touchpad]
          MatchVendor=0x045E
          MatchProduct=0x09AF
          MatchUdevType=touchpad
          AttrPressureRange=25:10
          AttrPalmPressureThreshold=500
        '')
        
        # Slate mode quirk - allows keyboard/touchpad to work in slate position
        # Fixes: keyboard/touchpad disabled when screen folded on Wayland
        (lib.mkIf cfg.quirks.slateModePeripherals ''
          [Microsoft Surface Laptop Studio Built-In Peripherals]
          MatchName=Microsoft Surface
          MatchDMIModalias=dmi:*svnMicrosoftCorporation:pnSurfaceLaptopStudio:*
          ModelTabletModeNoSuspend=1
        '')
      ];
      
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
      # AUDIO (Sample Rate)
      # ─────────────────────────────────────────────────────────────────────
      # Force 48kHz sample rate to avoid audio quality issues on SLS
      # See: https://github.com/linux-surface/linux-surface/wiki/Surface-Laptop-Studio
      # Note: PipeWire defaults to 48kHz, but we explicitly set it for safety
      services.pipewire.extraConfig.pipewire."91-surface-sample-rate" = 
        lib.mkIf (cfg.model == "laptop-studio" || cfg.model == "laptop-studio-2") {
          "context.properties" = {
            "default.clock.rate" = 48000;
            "default.clock.allowed-rates" = [ 48000 ];
          };
        };
      
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
      boot.kernelModules = lib.mkIf (cfg.model == "laptop-studio" || cfg.model == "laptop-studio-2") [
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

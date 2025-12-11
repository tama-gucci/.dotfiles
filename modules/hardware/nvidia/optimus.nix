{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.nvidia.optimus;
  nvidiaCfg = config.modules.nvidia;
in
{
  options.modules.nvidia.optimus = {
    enable = mkEnableOption "NVIDIA Optimus (hybrid laptop graphics)";
    
    mode = mkOption {
      type = types.enum [ "offload" "sync" "reverse-sync" ];
      default = "offload";
      description = ''
        Optimus mode:
        - offload: Use Intel by default, run specific apps on NVIDIA (best battery)
        - sync: Always use NVIDIA through Intel (best performance, worse battery)
        - reverse-sync: NVIDIA as primary, Intel for some outputs
      '';
    };
    
    intelBusId = mkOption {
      type = types.str;
      default = "PCI:0:2:0";
      description = "Bus ID of Intel GPU (find with: lspci | grep VGA)";
    };
    
    nvidiaBusId = mkOption {
      type = types.str;
      default = "PCI:1:0:0";
      description = "Bus ID of NVIDIA GPU (find with: lspci | grep VGA)";
    };
  };

  config = mkIf (nvidiaCfg.enable && cfg.enable) {
    # Enable fine-grained power management for Optimus laptops
    # Allows NVIDIA GPU to fully power down when not in use
    hardware.nvidia.powerManagement.finegrained = cfg.mode == "offload";
    
    # NVIDIA Prime configuration for hybrid graphics
    hardware.nvidia.prime = {
      # Set GPU bus IDs
      intelBusId = cfg.intelBusId;
      nvidiaBusId = cfg.nvidiaBusId;
      
      # Offload mode - run specific apps on NVIDIA with nvidia-offload wrapper
      offload = mkIf (cfg.mode == "offload") {
        enable = true;
        enableOffloadCmd = true;  # Adds nvidia-offload command
      };
      
      # Sync mode - always render on NVIDIA, display through Intel
      sync.enable = cfg.mode == "sync";
      
      # Reverse sync - NVIDIA primary, Intel for external displays
      reverseSync.enable = cfg.mode == "reverse-sync";
    };
    
    # Helper script for offload mode
    environment.systemPackages = mkIf (cfg.mode == "offload") [
      (pkgs.writeShellScriptBin "gpu-run" ''
        # Wrapper to run any command on the NVIDIA GPU
        # Usage: gpu-run <command>
        export __NV_PRIME_RENDER_OFFLOAD=1
        export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        export __VK_LAYER_NV_optimus=NVIDIA_only
        exec "$@"
      '')
    ];
    
    # Specialisation for on-demand NVIDIA mode toggle
    specialisation = {
      # Boot option for full NVIDIA performance (no battery savings)
      nvidia-sync.configuration = mkIf (cfg.mode == "offload") {
        hardware.nvidia.prime = {
          offload.enable = mkForce false;
          offload.enableOffloadCmd = mkForce false;
          sync.enable = mkForce true;
        };
        hardware.nvidia.powerManagement.finegrained = mkForce false;
      };
    };
  };
}

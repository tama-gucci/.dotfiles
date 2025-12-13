# ═══════════════════════════════════════════════════════════════════════════
# NVIDIA GPU SUPPORT
# ═══════════════════════════════════════════════════════════════════════════
# NVIDIA driver configuration for desktops and laptops
# Usage: Import flake.modules.nixos.nvidia in your configuration
{ config, inputs, ... }:
{
  flake.modules.nixos.nvidia = { pkgs, lib, config, ... }: {
    # ─────────────────────────────────────────────────────────────────────────
    # OPTIONS
    # ─────────────────────────────────────────────────────────────────────────
    options.nvidia = {
      useCustomKernel = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether to use CachyOS kernel. Set to false when using
          another specialized kernel (e.g., linux-surface).
        '';
      };
      
      prime = {
        enable = lib.mkEnableOption "NVIDIA Optimus (hybrid graphics)";
        mode = lib.mkOption {
          type = lib.types.enum [ "offload" "sync" "reverse-sync" ];
          default = "offload";
          description = ''
            Optimus mode:
            - offload: Intel by default, NVIDIA on demand (best battery)
            - sync: Always NVIDIA through Intel (best performance)
            - reverse-sync: NVIDIA primary
          '';
        };
        intelBusId = lib.mkOption {
          type = lib.types.str;
          default = "PCI:0:2:0";
          description = "Intel GPU bus ID";
        };
        nvidiaBusId = lib.mkOption {
          type = lib.types.str;
          default = "PCI:1:0:0";
          description = "NVIDIA GPU bus ID";
        };
      };
    };
    
    # ─────────────────────────────────────────────────────────────────────────
    # CONFIG
    # ─────────────────────────────────────────────────────────────────────────
    config = {
      # CachyOS kernel for better performance (unless using custom kernel)
      boot.kernelPackages = lib.mkIf config.nvidia.useCustomKernel 
        (lib.mkDefault pkgs.linuxPackages_cachyos-lto);
      
      # Preserve VRAM during suspend
      boot.kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];
      
      # X11/Wayland driver
      services.xserver.videoDrivers = [ "nvidia" ];
      
      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = true;
        powerManagement.finegrained = config.nvidia.prime.enable && config.nvidia.prime.mode == "offload";
        open = false;
        nvidiaSettings = true;
        # Use beta drivers from whatever kernel is configured
        package = config.boot.kernelPackages.nvidiaPackages.beta;
        
        # Prime configuration (for laptops)
        prime = lib.mkIf config.nvidia.prime.enable {
          intelBusId = config.nvidia.prime.intelBusId;
          nvidiaBusId = config.nvidia.prime.nvidiaBusId;
          
          offload = lib.mkIf (config.nvidia.prime.mode == "offload") {
            enable = true;
            enableOffloadCmd = true;
          };
          sync.enable = config.nvidia.prime.mode == "sync";
          reverseSync.enable = config.nvidia.prime.mode == "reverse-sync";
        };
      };
      
      # VA-API
      environment.variables.LIBVA_DRIVER_NAME = "nvidia";
      
      environment.systemPackages = with pkgs; [
        nvtopPackages.nvidia
      ] ++ lib.optionals (config.nvidia.prime.enable && config.nvidia.prime.mode == "offload") [
        # Offload helper script
        (writeShellScriptBin "gpu-run" ''
          export __NV_PRIME_RENDER_OFFLOAD=1
          export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
          export __GLX_VENDOR_LIBRARY_NAME=nvidia
          export __VK_LAYER_NV_optimus=NVIDIA_only
          exec "$@"
        '')
      ];
      
      # Specialisation for sync mode toggle (laptops)
      specialisation = lib.mkIf (config.nvidia.prime.enable && config.nvidia.prime.mode == "offload") {
        nvidia-sync.configuration = {
          hardware.nvidia.prime = {
            offload.enable = lib.mkForce false;
            offload.enableOffloadCmd = lib.mkForce false;
            sync.enable = lib.mkForce true;
          };
          hardware.nvidia.powerManagement.finegrained = lib.mkForce false;
        };
      };
    };
  };
}

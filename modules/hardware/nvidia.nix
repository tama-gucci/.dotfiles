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
      
      # Surface Laptop Studio specific workaround
      # See: https://github.com/linux-surface/linux-surface/wiki/Surface-Laptop-Studio#nvidia-gpu-locked-at-10w-power-limit
      disableRuntimeD3 = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Disable NVIDIA Runtime D3 power management.
          Required for Surface Laptop Studio to avoid GPU being locked to 10W.
          Note: This will increase power consumption as GPU cannot fully power down.
          Restores 35W of the 50W limit (remaining 15W is Dynamic Boost).
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
      
      # Disable Runtime D3 for Surface Laptop Studio GPU power limit fix
      # This prevents the GPU from getting stuck at 10W after D3cold transitions
      # See: https://github.com/linux-surface/linux-surface/wiki/Surface-Laptop-Studio
      boot.extraModprobeConfig = lib.mkIf config.nvidia.disableRuntimeD3 ''
        options nvidia "NVreg_DynamicPowerManagement=0x00"
      '';
      
      # X11/Wayland driver
      services.xserver.videoDrivers = [ "nvidia" ];
      
      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = true;
        # Finegrained PM uses Runtime D3 - disable if D3 is disabled
        powerManagement.finegrained = 
          config.nvidia.prime.enable 
          && config.nvidia.prime.mode == "offload"
          && !config.nvidia.disableRuntimeD3;
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

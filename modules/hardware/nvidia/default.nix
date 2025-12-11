{ config, lib, pkgs, inputs, ... }:

with lib;

{
  # Import optimus submodule
  imports = [ ./optimus.nix ];

  # Use custom namespace to avoid conflict with NixOS's hardware.nvidia
  options.modules.nvidia.enable = mkEnableOption "NVIDIA GPU support";

  config = mkIf config.modules.nvidia.enable {
    
    # Use CachyOS kernel for better gaming/desktop performance
    # Falls back to latest stable kernel if CachyOS unavailable
    boot.kernelPackages = pkgs.linuxPackages_cachyos-lto;
    
    # Preserve GPU memory during suspend/resume (prevents crashes)
    boot.kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];
    
    # Tell X11/Wayland to use NVIDIA driver
    services.xserver.videoDrivers = [ "nvidia" ];
    
    hardware.nvidia = {
      # Required for Wayland compositors (Hyprland, Sway, etc.)
      modesetting.enable = true;
      
      # Power management - reduces idle power consumption
      powerManagement.enable = true;
      powerManagement.finegrained = false;  # More aggressive power saving
      
      # Use proprietary driver (required for CUDA, better gaming performance)
      open = false;
      
      # Install nvidia-settings GUI tool
      nvidiaSettings = true;
      
      # Use stable driver (reliable for daily use)
      package = pkgs.linuxPackages_cachyos-lto.nvidiaPackages.beta;
    };
    
    # OpenGL - required for 3D graphics acceleration
    hardware.graphics = {
      enable = true;            # Standard 3D rendering
      enable32Bit = true;   # 32-bit app support (Steam, Wine)
    };
    
    environment.systemPackages = with pkgs; [ nvtopPackages.nvidia ];
    
    # Use NVIDIA for hardware video acceleration
    environment.variables.LIBVA_DRIVER_NAME = "nvidia";
  };
}

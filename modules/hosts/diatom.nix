# ═══════════════════════════════════════════════════════════════════════════
# HOST: DIATOM
# ═══════════════════════════════════════════════════════════════════════════
# Microsoft Surface Laptop Studio - Intel CPU, NVIDIA GPU (Optimus)
{ lib, config, inputs, pkgs, modulesPath, ... }:
let
  modules = config.flake.modules.nixos;
in
{
  # ─────────────────────────────────────────────────────────────────────────
  # HOST CONFIGURATION
  # ─────────────────────────────────────────────────────────────────────────
  configurations.nixos.diatom = {
    system = "x86_64-linux";
    
    modules = [
      # Core modules (in order of inheritance)
      modules.laptop             # Includes base → pc → laptop (power management)
      modules.nvidia             # NVIDIA drivers (with Optimus support)
      modules.surface            # Surface hardware (patched kernel, iptsd, etc.)
      modules.secureboot         # Lanzaboote
      
      # Interface
      modules.hyprland           # Window manager
      modules.noctalia           # Desktop shell
      
      # Applications
      modules.gaming             # Steam, Lutris, etc.
      modules.development        # Dev tools
      modules.zen-browser        # Browser
      
      # Hardware-specific configuration
      ({ config, lib, pkgs, modulesPath, ... }: {
        imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
        
        networking.hostName = "diatom";
        
        # ─────────────────────────────────────────────────────────────────
        # SURFACE LAPTOP STUDIO CONFIGURATION
        # ─────────────────────────────────────────────────────────────────
        surface = {
          model = "laptop-studio";
          kernelVersion = "stable";  # Newer kernel for better hardware support
          touchscreen.enable = true;
        };
        
        # ─────────────────────────────────────────────────────────────────
        # NVIDIA OPTIMUS (LAPTOP)
        # ─────────────────────────────────────────────────────────────────
        # Surface Laptop Studio has RTX 3050 Ti
        # Bus IDs: run `lspci | grep VGA` to verify
        nvidia = {
          useCustomKernel = false;  # Use linux-surface kernel from Surface module
          prime = {
            enable = true;
            mode = "offload";  # Best battery life; use "sync" for performance
            intelBusId = "PCI:0:2:0";
            nvidiaBusId = "PCI:1:0:0";
          };
        };
        
        # ─────────────────────────────────────────────────────────────────
        # HIBERNATION
        # ─────────────────────────────────────────────────────────────────
        hibernation = {
          enable = true;
          device = "/dev/nvme0n1p2";  # Adjust based on actual disk
          offset = "533760";          # From: sudo filefrag -v /swap/swapfile
          swapSize = "32G";
        };
        
        # ─────────────────────────────────────────────────────────────────
        # BOOT & KERNEL
        # ─────────────────────────────────────────────────────────────────
        boot.initrd.availableKernelModules = [ 
          "xhci_pci" 
          "thunderbolt" 
          "nvme" 
          "usb_storage" 
          "sd_mod"
          # Surface-specific modules for early boot
          "surface_aggregator"
          "surface_aggregator_registry" 
        ];
        boot.kernelModules = [ "kvm-intel" ];
        
        # ─────────────────────────────────────────────────────────────────
        # PLACEHOLDER: FILESYSTEMS
        # ─────────────────────────────────────────────────────────────────
        # TODO: Run nixos-generate-config and update these UUIDs
        # boot.initrd.luks.devices."encrypted".device = 
        #   "/dev/disk/by-uuid/YOUR-LUKS-UUID";
        
        # fileSystems."/" = {
        #   device = "/dev/disk/by-uuid/YOUR-ROOT-UUID";
        #   fsType = "btrfs";
        #   options = [ "subvol=root" "compress=zstd" "noatime" ];
        # };
        
        # fileSystems."/boot" = {
        #   device = "/dev/disk/by-uuid/YOUR-BOOT-UUID";
        #   fsType = "vfat";
        # };
        
        # ─────────────────────────────────────────────────────────────────
        # HARDWARE
        # ─────────────────────────────────────────────────────────────────
        hardware.cpu.intel.updateMicrocode = 
          lib.mkDefault config.hardware.enableRedistributableFirmware;
        
        nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
        
        # ─────────────────────────────────────────────────────────────────
        # LAPTOP STUDIO SPECIFIC SERVICES
        # ─────────────────────────────────────────────────────────────────
        services.openssh.enable = true;
        
        # Backlight control (screen + keyboard)
        programs.light.enable = true;
      })
    ];
  };
}

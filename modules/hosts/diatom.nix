# ═══════════════════════════════════════════════════════════════════════════
# HOST: DIATOM
# ═══════════════════════════════════════════════════════════════════════════
# Microsoft Surface Laptop Studio - Intel CPU, NVIDIA GPU (Optimus)
{ config, ... }:
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
      modules.hibernation
      
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
          
          # Fix for GPU locked at 10W power limit on Surface Laptop Studio
          # This disables Runtime D3, restoring 35W of the 50W limit
          # Trade-off: Higher idle power consumption (GPU cannot fully power down)
          # See: https://github.com/linux-surface/linux-surface/wiki/Surface-Laptop-Studio
          disableRuntimeD3 = true;
          
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
        # FILESYSTEMS
        # ─────────────────────────────────────────────────────────────────
        # LUKS device
        boot.initrd.luks.devices."encrypted".device = 
          "/dev/disk/by-uuid/d72eaf4b-0f3d-400e-9c2c-309845cd7475";

        # Root filesystem
        fileSystems."/" = {
          device = "/dev/disk/by-uuid/47352277-92e3-49cb-9a5e-551a6850c619";
          fsType = "btrfs";
          options = [ "subvol=root" "compress=zstd" "noatime" "ssd" "discard=async" ];
        };

        fileSystems."/home" = {
          device = "/dev/disk/by-uuid/47352277-92e3-49cb-9a5e-551a6850c619";
          fsType = "btrfs";
          options = [ "subvol=home" "compress=zstd" "noatime" "ssd" "discard=async" ];
        };

        fileSystems."/nix" = {
          device = "/dev/disk/by-uuid/47352277-92e3-49cb-9a5e-551a6850c619";
          fsType = "btrfs";
          options = [ "subvol=nix" "compress=zstd" "noatime" "ssd" "discard=async" ];
        };

        fileSystems."/persist" = {
          device = "/dev/disk/by-uuid/47352277-92e3-49cb-9a5e-551a6850c619";
          fsType = "btrfs";
          options = [ "subvol=persist" "compress=zstd" "noatime" "ssd" "discard=async" ];
        };

        fileSystems."/var/log" = {
          device = "/dev/disk/by-uuid/47352277-92e3-49cb-9a5e-551a6850c619";
          fsType = "btrfs";
          options = [ "subvol=log" "compress=zstd" "noatime" "ssd" "discard=async" ];
          neededForBoot = true;
        };

        fileSystems."/swap" = {
          device = "/dev/disk/by-uuid/47352277-92e3-49cb-9a5e-551a6850c619";
          fsType = "btrfs";
          options = [ "subvol=swap" "noatime" ];
        };

        fileSystems."/boot" = {
          device = "/dev/disk/by-uuid/A9C0-146A";
          fsType = "vfat";
        };      

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



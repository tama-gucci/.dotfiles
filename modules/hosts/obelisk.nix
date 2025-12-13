# ═══════════════════════════════════════════════════════════════════════════
# HOST: OBELISK
# ═══════════════════════════════════════════════════════════════════════════
# Desktop PC - Intel CPU, NVIDIA GPU
{ lib, config, inputs, pkgs, modulesPath, ... }:
let
  modules = config.flake.modules.nixos;
in
{
  # ─────────────────────────────────────────────────────────────────────────
  # HOST CONFIGURATION
  # ─────────────────────────────────────────────────────────────────────────
  configurations.nixos.obelisk = {
    system = "x86_64-linux";
    
    modules = [
      # Core modules (in order of inheritance)
      modules.desktop           # Includes base → pc → desktop
      modules.nvidia            # NVIDIA drivers
      modules.secureboot        # Lanzaboote
      
      # Interface
      modules.hyprland          # Window manager
      modules.noctalia          # Desktop shell
      
      # Applications
      modules.gaming            # Steam, Lutris, etc.
      modules.development       # Dev tools
      modules.zen-browser       # Browser
      
      # Hardware-specific configuration
      ({ config, lib, pkgs, modulesPath, ... }: {
        imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
        
        networking.hostName = "obelisk";
        
        # ─────────────────────────────────────────────────────────────────
        # BOOT & KERNEL
        # ─────────────────────────────────────────────────────────────────
        boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
        boot.kernelModules = [ "kvm-intel" ];
        
        # ─────────────────────────────────────────────────────────────────
        # LUKS ENCRYPTION
        # ─────────────────────────────────────────────────────────────────
        boot.initrd.luks.devices."lockedPartition".device = 
          "/dev/disk/by-uuid/e0043e40-80cb-4c69-a896-20260958d8de";
        
        # ─────────────────────────────────────────────────────────────────
        # FILESYSTEMS (BTRFS)
        # ─────────────────────────────────────────────────────────────────
        fileSystems = let
          btrfsOpts = [ "compress=zstd" "noatime" ];
          btrfsDev = "/dev/disk/by-uuid/5463af7b-e287-4f0c-8a3a-d87398592c2b";
        in {
          "/" = {
            device = btrfsDev;
            fsType = "btrfs";
            options = [ "subvol=root" ] ++ btrfsOpts;
          };
          "/home" = {
            device = btrfsDev;
            fsType = "btrfs";
            options = [ "subvol=home" ] ++ btrfsOpts;
          };
          "/nix" = {
            device = btrfsDev;
            fsType = "btrfs";
            options = [ "subvol=nix" ] ++ btrfsOpts;
          };
          "/persist" = {
            device = btrfsDev;
            fsType = "btrfs";
            options = [ "subvol=persist" ] ++ btrfsOpts;
            neededForBoot = true;
          };
          "/var/log" = {
            device = btrfsDev;
            fsType = "btrfs";
            options = [ "subvol=log" ] ++ btrfsOpts;
            neededForBoot = true;
          };
          "/swap" = {
            device = btrfsDev;
            fsType = "btrfs";
            options = [ "subvol=swap" "noatime" ];
          };
          "/boot" = {
            device = "/dev/disk/by-uuid/E854-1E66";
            fsType = "vfat";
            options = [ "fmask=0022" "dmask=0022" ];
          };
        };
        
        # ─────────────────────────────────────────────────────────────────
        # SWAP & HIBERNATION
        # ─────────────────────────────────────────────────────────────────
        swapDevices = [{ 
          device = "/swap/swapfile"; 
          size = 20 * 1024;  # 20GB
        }];
        
        # ─────────────────────────────────────────────────────────────────
        # HARDWARE
        # ─────────────────────────────────────────────────────────────────
        hardware.cpu.intel.updateMicrocode = 
          lib.mkDefault config.hardware.enableRedistributableFirmware;
        
        nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      })
    ];
  };
}

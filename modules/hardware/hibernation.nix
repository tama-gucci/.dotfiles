# ═══════════════════════════════════════════════════════════════════════════
# HIBERNATION MODULE
# ═══════════════════════════════════════════════════════════════════════════
# Swapfile-based hibernation with proper resume configuration
{ lib, config, ... }:
let
  cfg = config.hibernation;
in
{
  options.hibernation = {
    enable = lib.mkEnableOption "swapfile-based hibernation";
    
    device = lib.mkOption {
      type = lib.types.str;
      default = "/dev/nvme0n1p2";
      description = "Block device containing the swapfile";
    };
    
    offset = lib.mkOption {
      type = lib.types.str;
      description = "Swap file offset (from `filefrag -v /swap/swapfile`)";
    };
    
    swapSize = lib.mkOption {
      type = lib.types.str;
      default = "32G";
      description = "Size of the swapfile";
    };
  };

  config = lib.mkIf cfg.enable {
    # Swapfile on btrfs requires special handling
    swapDevices = [{
      device = "/swap/swapfile";
      size = lib.toInt (lib.removeSuffix "G" cfg.swapSize) * 1024;
    }];

    # Resume parameters for hibernation
    boot = {
      resumeDevice = cfg.device;
      kernelParams = [ "resume_offset=${cfg.offset}" ];
    };

    # Required for suspend-then-hibernate
    systemd.sleep.extraConfig = ''
      HibernateDelaySec=30m
    '';
  };
}

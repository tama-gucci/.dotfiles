{ config, lib, ... }:

with lib;

let
  cfg = config.modules.hibernation;
in
{
  options.modules.hibernation = {
    enable = mkEnableOption "hibernation support";
    
    resumeDevice = mkOption {
      type = types.str;
      description = "UUID of the partition containing the swap file/partition";
      example = "5463af7b-e287-4f0c-8a3a-d87398592c2b";
    };
    
    swapfileOffset = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        Physical offset of the swapfile for btrfs or other filesystems.
        Get this with: sudo btrfs inspect-internal map-swapfile -r /path/to/swapfile
        Or: sudo filefrag -v /path/to/swapfile | awk 'NR==4 {print $4}'
        Set to null if using a swap partition instead of swapfile.
      '';
      example = 968969;
    };
  };

  config = mkIf cfg.enable {
    # Resume device for hibernation
    boot.resumeDevice = "/dev/disk/by-uuid/${cfg.resumeDevice}";
    
    # Kernel parameters for resume
    boot.kernelParams = [
      "resume=UUID=${cfg.resumeDevice}"
    ] ++ optionals (cfg.swapfileOffset != null) [
      "resume_offset=${toString cfg.swapfileOffset}"
    ];
    
    # Ensure resume is available in initrd
    boot.initrd.systemd.enable = mkDefault true;
    
    # Allow suspend-then-hibernate
    systemd.sleep.extraConfig = ''
      AllowSuspend=yes
      AllowHibernation=yes
      AllowSuspendThenHibernate=yes
      AllowHybridSleep=yes
      HibernateDelaySec=1h
    '';
    
    # Power button behavior
    services.logind.settings.Login = {
      HandleLidSwitch = "suspend-then-hibernate";
      HandlePowerKey = "hibernate";
      HandlePowerKeyLongPress = "poweroff";
    };
  };
}

{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.modules.hyprland.caelestia;
  hyprCfg = config.modules.hyprland;
  username = config.modules.user.name;
  system = pkgs.stdenv.hostPlatform.system;
  hasPkg = builtins.hasAttr system inputs.caelestia-shell.packages;
in
{
  options.modules.hyprland.caelestia = {
    enable = mkEnableOption "Caelestia shell environment";
    
    wallpaperDir = mkOption {
      type = types.str;
      default = "~/Pictures/Wallpapers";
      description = "Path to wallpaper directory";
    };
    
    showBattery = mkOption {
      type = types.bool;
      default = true;
      description = "Show battery status in bar";
    };
    
    transparency = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable transparency effects";
      };
      base = mkOption {
        type = types.float;
        default = 0.85;
        description = "Base transparency level";
      };
    };
  };

  config = mkIf (hyprCfg.enable && cfg.enable && hasPkg) {
    # Install Caelestia system-wide
    environment.systemPackages = [ 
      inputs.caelestia-shell.packages.${system}.default 
    ];
    
    # Add Caelestia to Hyprland's exec-once
    # This merges with the existing exec-once from default.nix
    home-manager.users.${username} = {
      imports = [ inputs.caelestia-shell.homeManagerModules.default ];
      
      # Caelestia configuration
      programs.caelestia = { 
        enable = true;
        systemd.enable = false;
        
        settings = {
          appearance = {
            anim.durations.scale = 1;
            font = {
              family = {
                clock = "Rubik";
                material = "Material Symbols Rounded";
                mono = "CaskaydiaCove NF";
                sans = "Rubik";
              };
              size.scale = 1;
            };
            padding.scale = 1;
            rounding.scale = 1;
            spacing.scale = 1;
            transparency = {
              enabled = cfg.transparency.enable;
              base = cfg.transparency.base;
              layers = 0.4;
            };
          };
          
          general = {
            apps = {
              terminal = [ hyprCfg.terminal ];
              audio = [ "pavucontrol" ];
              playback = [ "mpv" ];
              explorer = [ hyprCfg.fileManager ];
            };
            battery = {
              warnLevels = [
                { level = 20; title = "Low battery"; message = "You might want to plug in a charger"; icon = "battery_android_frame_2"; }
                { level = 10; title = "Battery warning"; message = "You should probably plug in a charger <b>now</b>"; icon = "battery_android_frame_1"; }
                { level = 5; title = "Critical battery"; message = "PLUG THE CHARGER RIGHT NOW!!"; icon = "battery_android_alert"; critical = true; }
              ];
              criticalLevel = 3;
            };
            idle = {
              lockBeforeSleep = true;
              inhibitWhenAudio = true;
              timeouts = [
                { timeout = 180; idleAction = "lock"; }
                { timeout = 300; idleAction = "dpms off"; returnAction = "dpms on"; }
                { timeout = 600; idleAction = [ "systemctl" "suspend-then-hibernate" ]; }
              ];
            };
          };
          
          background = {
            enabled = true;
            desktopClock.enabled = false;
            visualiser = {
              enabled = false;
              blur = false;
              autoHide = true;
            };
          };
          
          bar = {
            clock.showIcon = true;
            dragThreshold = 20;
            persistent = true;
            showOnHover = true;
            entries = [
              { id = "logo"; enabled = true; }
              { id = "workspaces"; enabled = true; }
              { id = "spacer"; enabled = true; }
              { id = "activeWindow"; enabled = true; }
              { id = "spacer"; enabled = true; }
              { id = "tray"; enabled = true; }
              { id = "clock"; enabled = true; }
              { id = "statusIcons"; enabled = true; }
              { id = "power"; enabled = true; }
            ];
            popouts = { activeWindow = true; statusIcons = true; tray = true; };
            scrollActions = { brightness = true; workspaces = true; volume = true; };
            status = {
              showAudio = false;
              showBattery = cfg.showBattery;
              showBluetooth = true;
              showKbLayout = false;
              showMicrophone = false;
              showNetwork = true;
              showLockStatus = true;
            };
            workspaces = {
              activeIndicator = true;
              activeLabel = "󰮯";
              occupiedLabel = "󰮯";
              label = "  ";
              perMonitorWorkspaces = true;
              showWindows = true;
              shown = 5;
            };
          };
          
          border = { rounding = 25; thickness = 10; };
          
          dashboard = {
            enabled = true;
            dragThreshold = 50;
            mediaUpdateInterval = 500;
            showOnHover = true;
          };
          
          launcher = {
            actionPrefix = ">";
            dragThreshold = 50;
            maxShown = 7;
            maxWallpapers = 9;
            specialPrefix = "@";
            enableDangerousActions = false;
            actions = [
              { name = "Calculator"; icon = "calculate"; description = "Math equations"; command = [ "autocomplete" "calc" ]; enabled = true; dangerous = false; }
              { name = "Scheme"; icon = "palette"; description = "Change colour scheme"; command = [ "autocomplete" "scheme" ]; enabled = true; dangerous = false; }
              { name = "Wallpaper"; icon = "image"; description = "Change wallpaper"; command = [ "autocomplete" "wallpaper" ]; enabled = true; dangerous = false; }
              { name = "Random"; icon = "casino"; description = "Random wallpaper"; command = [ "caelestia" "wallpaper" "-r" ]; enabled = true; dangerous = false; }
              { name = "Light"; icon = "light_mode"; description = "Light mode"; command = [ "setMode" "light" ]; enabled = true; dangerous = false; }
              { name = "Dark"; icon = "dark_mode"; description = "Dark mode"; command = [ "setMode" "dark" ]; enabled = true; dangerous = false; }
              { name = "Lock"; icon = "lock"; description = "Lock session"; command = [ "loginctl" "lock-session" ]; enabled = true; dangerous = false; }
              { name = "Sleep"; icon = "bedtime"; description = "Suspend"; command = [ "systemctl" "suspend-then-hibernate" ]; enabled = true; dangerous = false; }
              { name = "Shutdown"; icon = "power_settings_new"; description = "Shutdown"; command = [ "systemctl" "poweroff" ]; enabled = true; dangerous = true; }
              { name = "Reboot"; icon = "cached"; description = "Reboot"; command = [ "systemctl" "reboot" ]; enabled = true; dangerous = true; }
            ];
          };
          
          notifs = { defaultExpireTimeout = 5000; expire = false; };
          osd = { enabled = true; enableBrightness = true; hideDelay = 2000; };
          paths = { wallpaperDir = cfg.wallpaperDir; };
          services = { audioIncrement = 0.1; maxVolume = 1.0; smartScheme = true; };
          session = { enabled = true; };
          sidebar = { enabled = true; dragThreshold = 80; };
          utilities = { enabled = true; maxToasts = 4; };
        };
        
        cli = {
          enable = true;
          settings.theme.enableGtk = false;
        };
      };
      
      # Add caelestia-shell to Hyprland exec-once
      # This uses mkOptionDefault to append rather than override
      wayland.windowManager.hyprland.settings.exec-once = 
        mkOptionDefault [ "caelestia-shell" ];
    };
  };
}

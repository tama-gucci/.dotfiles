{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.modules.noctalia;
  username = config.modules.user.name;
  system = pkgs.stdenv.hostPlatform.system;
  
  # Check if Noctalia flake input exists
  hasNoctalia = builtins.hasAttr "noctalia" inputs;
  
  # Helper function to generate Noctalia IPC commands
  # Used for keybindings in both Hyprland and Niri
  noctaliaCmd = cmd: "noctalia-shell ipc call ${cmd}";
  
  # Helper for Niri bindings (requires list format)
  noctaliaCmdList = cmd: [ "noctalia-shell" "ipc" "call" ] ++ (lib.splitString " " cmd);
  
  # Determine if each WM should be enabled based on selection
  isHyprland = cfg.windowManager == "hyprland";
  isNiri = cfg.windowManager == "niri";
  
in
{
  options.modules.noctalia = {
    enable = mkEnableOption "Noctalia shell environment";
    
    # ─────────────────────────────────────────────────────────────
    # WINDOW MANAGER SELECTION
    # This is the primary switch for choosing your compositor
    # ─────────────────────────────────────────────────────────────
    windowManager = mkOption {
      type = types.enum [ "hyprland" "niri" ];
      default = "hyprland";
      description = ''
        Which window manager/compositor to use with Noctalia.
        This option enables the corresponding WM module and configures
        Noctalia's keybindings appropriately.
      '';
    };
    
    # ─────────────────────────────────────────────────────────────
    # SESSION SETTINGS
    # Shared between both window managers
    # ─────────────────────────────────────────────────────────────
    autoLogin = mkOption {
      type = types.bool;
      default = true;
      description = "Auto-login the user and start the session";
    };
    
    terminal = mkOption {
      type = types.str;
      default = "kitty";
      description = "Default terminal application";
    };
    
    fileManager = mkOption {
      type = types.str;
      default = "nautilus";
      description = "Default file manager";
    };
    
    # ─────────────────────────────────────────────────────────────
    # CURSOR CONFIGURATION
    # Applied to both Wayland and X11 (for XWayland)
    # ─────────────────────────────────────────────────────────────
    cursor = {
      name = mkOption {
        type = types.str;
        default = "Bibata-Modern-Classic";
        description = "Cursor theme name";
      };
      size = mkOption {
        type = types.int;
        default = 24;
        description = "Cursor size";
      };
    };
    
    # ─────────────────────────────────────────────────────────────
    # NOCTALIA SHELL CONFIGURATION
    # ─────────────────────────────────────────────────────────────
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
    
    bar = {
      position = mkOption {
        type = types.enum [ "top" "bottom" "left" "right" ];
        default = "top";
        description = "Bar position on screen";
      };
      
      density = mkOption {
        type = types.enum [ "default" "compact" "expanded" ];
        default = "default";
        description = "Bar density/spacing";
      };
      
      floating = mkOption {
        type = types.bool;
        default = false;
        description = "Whether the bar floats above windows";
      };
    };
    
    useSystemd = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Run Noctalia as a systemd service instead of spawning at startup.
        Note: The systemd service is experimental and may cause issues.
      '';
    };
    
    # ─────────────────────────────────────────────────────────────
    # EXTRA SETTINGS
    # Pass-through for advanced Noctalia configuration
    # ─────────────────────────────────────────────────────────────
    extraSettings = mkOption {
      type = types.attrs;
      default = {};
      description = ''
        Additional Noctalia settings to merge with defaults.
        See: https://github.com/noctalia-dev/noctalia-shell/blob/main/Assets/settings-default.json
      '';
    };
    
    colors = mkOption {
      type = types.nullOr types.attrs;
      default = null;
      description = ''
        Material 3 color scheme for Noctalia.
        If null, Noctalia uses its default theme.
        When setting, ALL color values must be provided.
      '';
    };
  };

  config = mkIf (cfg.enable && hasNoctalia) {
    # ─────────────────────────────────────────────────────────────
    # ASSERTIONS
    # Ensure configuration is valid
    # ─────────────────────────────────────────────────────────────
    assertions = [
      {
        assertion = hasNoctalia;
        message = ''
          Noctalia shell requires the 'noctalia' flake input.
          Add to your flake.nix inputs:
            noctalia = {
              url = "github:noctalia-dev/noctalia-shell";
              inputs.nixpkgs.follows = "nixpkgs";
            };
        '';
      }
    ];
    
    # ─────────────────────────────────────────────────────────────
    # NIXOS MODULE IMPORT
    # Import Noctalia's NixOS module for systemd service support
    # ─────────────────────────────────────────────────────────────
    imports = [ inputs.noctalia.nixosModules.default ];
    
    # Enable systemd service if configured
    services.noctalia-shell = mkIf cfg.useSystemd {
      enable = true;
    };
    
    # ─────────────────────────────────────────────────────────────
    # ENABLE SELECTED WINDOW MANAGER
    # This delegates to the appropriate WM module
    # ─────────────────────────────────────────────────────────────
    modules.hyprland = mkIf isHyprland {
      enable = true;
      autoLogin = cfg.autoLogin;
      terminal = cfg.terminal;
      fileManager = cfg.fileManager;
      cursor = cfg.cursor;
    };
    
    modules.niri = mkIf isNiri {
      enable = true;
      autoLogin = cfg.autoLogin;
      terminal = cfg.terminal;
    };
    
    # ─────────────────────────────────────────────────────────────
    # REQUIRED SYSTEM SERVICES
    # Noctalia needs these for wifi, bluetooth, power features
    # ─────────────────────────────────────────────────────────────
    networking.networkmanager.enable = mkDefault true;
    services.upower.enable = mkDefault true;
    services.power-profiles-daemon.enable = mkDefault true;
    
    # ─────────────────────────────────────────────────────────────
    # HOME MANAGER CONFIGURATION
    # ─────────────────────────────────────────────────────────────
    home-manager.users.${username} = { config, ... }: {
      # Import Noctalia's home-manager module
      imports = [ inputs.noctalia.homeModules.default ];
      
      # ───────────────────────────────────────────────────────────
      # NOCTALIA SHELL PROGRAM CONFIGURATION
      # ───────────────────────────────────────────────────────────
      programs.noctalia-shell = {
        enable = true;
        
        # When using systemd service from NixOS module, set package to null
        # to avoid IPC command conflicts
        package = mkIf cfg.useSystemd null;
        
        # Enable home-manager systemd service only if NOT using NixOS service
        systemd.enable = !cfg.useSystemd;
        
        # Color scheme (optional)
        colors = mkIf (cfg.colors != null) cfg.colors;
        
        # Noctalia settings with sensible defaults
        settings = lib.recursiveUpdate {
          # Bar configuration
          bar = {
            position = cfg.bar.position;
            density = cfg.bar.density;
            floating = cfg.bar.floating;
            showCapsule = true;
            exclusive = true;
            
            widgets = {
              left = [
                { id = "ControlCenter"; useDistroLogo = true; }
                { id = "WiFi"; }
                { id = "Bluetooth"; }
              ];
              center = [
                { id = "Workspace"; hideUnoccupied = false; labelMode = "none"; }
              ];
              right = [
                (mkIf cfg.showBattery { 
                  id = "Battery"; 
                  alwaysShowPercentage = false; 
                  warningThreshold = 30; 
                })
                { 
                  id = "Clock"; 
                  formatHorizontal = "HH:mm"; 
                  formatVertical = "HH mm"; 
                  useMonospacedFont = true; 
                }
              ];
            };
          };
        } cfg.extraSettings;
      };
      
      # ───────────────────────────────────────────────────────────
      # HYPRLAND-SPECIFIC CONFIGURATION
      # Add Noctalia keybinds and startup to Hyprland
      # ───────────────────────────────────────────────────────────
      wayland.windowManager.hyprland = mkIf isHyprland {
        settings = {
          # Spawn Noctalia at startup (if not using systemd)
          exec-once = mkIf (!cfg.useSystemd) (mkOptionDefault [ "noctalia-shell" ]);
          
          # Noctalia-specific keybindings
          bind = mkOptionDefault [
            # Launcher toggle
            "SUPER, Space, exec, ${noctaliaCmd "launcher toggle"}"
            
            # Control center / session menu
            "SUPER, A, exec, ${noctaliaCmd "controlCenter toggle"}"
            "SUPER, Escape, exec, ${noctaliaCmd "sessionMenu toggle"}"
            
            # Lock screen
            "SUPER CTRL, L, exec, ${noctaliaCmd "lockScreen toggle"}"
            
            # Volume controls (using Noctalia's OSD)
            ", XF86AudioRaiseVolume, exec, ${noctaliaCmd "volume increase"}"
            ", XF86AudioLowerVolume, exec, ${noctaliaCmd "volume decrease"}"
            ", XF86AudioMute, exec, ${noctaliaCmd "volume muteOutput"}"
            ", XF86AudioMicMute, exec, ${noctaliaCmd "volume muteInput"}"
            
            # Brightness controls (using Noctalia's OSD)
            ", XF86MonBrightnessUp, exec, ${noctaliaCmd "brightness increase"}"
            ", XF86MonBrightnessDown, exec, ${noctaliaCmd "brightness decrease"}"
          ];
        };
      };
      
      # ───────────────────────────────────────────────────────────
      # NIRI-SPECIFIC CONFIGURATION
      # Override spawn-at-startup and binds for Niri
      # ───────────────────────────────────────────────────────────
      # Note: Niri config is handled via xdg.configFile in the niri module
      # We'll create a separate overlay mechanism for Niri binds
    };
    
    # ─────────────────────────────────────────────────────────────
    # ENVIRONMENT PACKAGES
    # ─────────────────────────────────────────────────────────────
    environment.systemPackages = with pkgs; [
      # Noctalia shell package
      inputs.noctalia.packages.${system}.default
      
      # Clipboard support
      wl-clipboard
    ];
  };
}

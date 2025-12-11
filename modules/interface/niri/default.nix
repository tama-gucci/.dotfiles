{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.niri;
  username = config.modules.user.name;
  monitorsCfg = config.modules.monitors;
in
{
  options.modules.niri = {
    enable = mkEnableOption "Niri scrolling window manager";
    
    autoLogin = mkOption {
      type = types.bool;
      default = true;
      description = "Auto-login the user and start Niri session";
    };
    
    terminal = mkOption {
      type = types.str;
      default = "alacritty";
      description = "Default terminal application";
    };
    
    launcher = mkOption {
      type = types.str;
      default = "fuzzel";
      description = "Application launcher command";
    };
  };

  config = mkIf cfg.enable {
    # Enable Niri compositor
    programs.niri = {
      enable = true;
      package = pkgs.niri;
    };
    
    # Environment variables for Wayland
    environment.sessionVariables = {
      XDG_CURRENT_DESKTOP = "niri";
      XDG_SESSION_TYPE = "wayland";
      NIXOS_OZONE_WL = "1";  # Electron apps on Wayland
    };
    
    # Auto-login with greetd
    services.greetd = mkIf cfg.autoLogin {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.niri}/bin/niri-session";
          user = username;
        };
      };
    };
    
    # Essential Wayland packages
    environment.systemPackages = with pkgs; [
      # Launchers
      fuzzel              # Application launcher
      wofi                # Alternative launcher
      
      # Notifications
      mako                # Notification daemon
      libnotify           # notify-send command
      
      # Screen utilities
      grim                # Screenshot tool
      slurp               # Region selection
      swappy              # Screenshot editor
      wl-clipboard        # Clipboard utilities
      
      # Display/lock
      swaylock            # Screen locker
      swayidle            # Idle management
      
      # Status bar
      waybar              # Highly customizable bar
      
      # Wallpaper
      swaybg              # Wallpaper setter
      
      # Brightness/audio
      brightnessctl       # Brightness control
      pamixer             # Audio control
      playerctl           # Media player control
    ];
    
    # XDG portal for screen sharing, file dialogs
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
    
    # Home Manager configuration
    home-manager.users.${username} = {
      # Niri configuration
      xdg.configFile."niri/config.kdl".text = ''
        // Niri configuration
        // See: https://github.com/YaLTeR/niri/wiki/Configuration
        
        input {
            keyboard {
                xkb {
                    layout "us"
                }
            }
            
            touchpad {
                tap
                natural-scroll
                accel-speed 0.2
            }
            
            mouse {
                accel-speed 0.0
            }
        }
        
        ${if monitorsCfg.displays != [] then monitorsCfg.niriConfig else ''output "eDP-1" {
            scale 1.0
        }''}
        
        layout {
            gaps 16
            
            center-focused-column "never"
            
            preset-column-widths {
                proportion 0.33333
                proportion 0.5
                proportion 0.66667
            }
            
            default-column-width { proportion 0.5; }
            
            focus-ring {
                width 2
                active-color "#7fc8ff"
                inactive-color "#505050"
            }
            
            border {
                off
            }
        }
        
        spawn-at-startup "${cfg.terminal}"
        spawn-at-startup "waybar"
        spawn-at-startup "swaybg" "-i" "~/Pictures/wallpaper.png" "-m" "fill"
        spawn-at-startup "mako"
        
        prefer-no-csd
        
        screenshot-path "~/Pictures/Screenshots/%Y-%m-%d_%H-%M-%S.png"
        
        binds {
            // Terminal
            Mod+Return { spawn "${cfg.terminal}"; }
            
            // Launcher
            Mod+D { spawn "${cfg.launcher}"; }
            
            // Close window
            Mod+Q { close-window; }
            
            // Exit niri
            Mod+Shift+E { quit; }
            
            // Focus navigation
            Mod+H { focus-column-left; }
            Mod+J { focus-window-down; }
            Mod+K { focus-window-up; }
            Mod+L { focus-column-right; }
            
            Mod+Left { focus-column-left; }
            Mod+Down { focus-window-down; }
            Mod+Up { focus-window-up; }
            Mod+Right { focus-column-right; }
            
            // Move windows
            Mod+Shift+H { move-column-left; }
            Mod+Shift+J { move-window-down; }
            Mod+Shift+K { move-window-up; }
            Mod+Shift+L { move-column-right; }
            
            Mod+Shift+Left { move-column-left; }
            Mod+Shift+Down { move-window-down; }
            Mod+Shift+Up { move-window-up; }
            Mod+Shift+Right { move-column-right; }
            
            // First/last column
            Mod+Home { focus-column-first; }
            Mod+End { focus-column-last; }
            Mod+Shift+Home { move-column-to-first; }
            Mod+Shift+End { move-column-to-last; }
            
            // Workspaces
            Mod+1 { focus-workspace 1; }
            Mod+2 { focus-workspace 2; }
            Mod+3 { focus-workspace 3; }
            Mod+4 { focus-workspace 4; }
            Mod+5 { focus-workspace 5; }
            Mod+6 { focus-workspace 6; }
            Mod+7 { focus-workspace 7; }
            Mod+8 { focus-workspace 8; }
            Mod+9 { focus-workspace 9; }
            
            Mod+Shift+1 { move-column-to-workspace 1; }
            Mod+Shift+2 { move-column-to-workspace 2; }
            Mod+Shift+3 { move-column-to-workspace 3; }
            Mod+Shift+4 { move-column-to-workspace 4; }
            Mod+Shift+5 { move-column-to-workspace 5; }
            Mod+Shift+6 { move-column-to-workspace 6; }
            Mod+Shift+7 { move-column-to-workspace 7; }
            Mod+Shift+8 { move-column-to-workspace 8; }
            Mod+Shift+9 { move-column-to-workspace 9; }
            
            // Workspace navigation
            Mod+Tab { focus-workspace-down; }
            Mod+Shift+Tab { focus-workspace-up; }
            
            // Column width
            Mod+R { switch-preset-column-width; }
            Mod+F { maximize-column; }
            Mod+Shift+F { fullscreen-window; }
            
            // Column/window management
            Mod+C { center-column; }
            Mod+Minus { set-column-width "-10%"; }
            Mod+Equal { set-column-width "+10%"; }
            Mod+Shift+Minus { set-window-height "-10%"; }
            Mod+Shift+Equal { set-window-height "+10%"; }
            
            // Consume/expel windows
            Mod+Comma { consume-window-into-column; }
            Mod+Period { expel-window-from-column; }
            
            // Screenshots
            Print { screenshot; }
            Mod+Print { screenshot-screen; }
            Mod+Shift+Print { screenshot-window; }
            
            // Volume control
            XF86AudioRaiseVolume { spawn "pamixer" "-i" "5"; }
            XF86AudioLowerVolume { spawn "pamixer" "-d" "5"; }
            XF86AudioMute { spawn "pamixer" "-t"; }
            
            // Brightness control
            XF86MonBrightnessUp { spawn "brightnessctl" "set" "+5%"; }
            XF86MonBrightnessDown { spawn "brightnessctl" "set" "5%-"; }
            
            // Media control
            XF86AudioPlay { spawn "playerctl" "play-pause"; }
            XF86AudioNext { spawn "playerctl" "next"; }
            XF86AudioPrev { spawn "playerctl" "previous"; }
            
            // Lock screen
            Mod+Escape { spawn "swaylock" "-f"; }
        }
      '';
      
      # Waybar configuration for Niri
      programs.waybar = {
        enable = true;
        settings = [{
          layer = "top";
          position = "top";
          height = 30;
          modules-left = [ "niri/workspaces" "niri/window" ];
          modules-center = [ "clock" ];
          modules-right = [ "pulseaudio" "network" "battery" "tray" ];
          
          clock = {
            format = "{:%H:%M}";
            format-alt = "{:%Y-%m-%d %H:%M}";
            tooltip-format = "{:%Y-%m-%d | %H:%M}";
          };
          
          battery = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{icon} {capacity}%";
            format-icons = [ "" "" "" "" "" ];
          };
          
          network = {
            format-wifi = " {signalStrength}%";
            format-ethernet = " Wired";
            format-disconnected = "󰖪 ";
            tooltip-format = "{essid} ({signalStrength}%)";
          };
          
          pulseaudio = {
            format = "{icon} {volume}%";
            format-muted = "󰝟";
            format-icons = { default = [ "" "" "" ]; };
            on-click = "pamixer -t";
          };
          
          tray = {
            spacing = 10;
          };
        }];
        
        style = ''
          * {
            font-family: "JetBrainsMono Nerd Font", monospace;
            font-size: 13px;
          }
          
          window#waybar {
            background-color: rgba(30, 30, 40, 0.9);
            color: #cdd6f4;
          }
          
          #workspaces button {
            padding: 0 8px;
            color: #cdd6f4;
            background: transparent;
            border: none;
          }
          
          #workspaces button.active {
            color: #89b4fa;
          }
          
          #clock, #battery, #network, #pulseaudio, #tray {
            padding: 0 10px;
          }
          
          #battery.warning {
            color: #f9e2af;
          }
          
          #battery.critical {
            color: #f38ba8;
          }
        '';
      };
      
      # Mako notification daemon
      services.mako = {
        enable = true;
        defaultTimeout = 5000;
        borderRadius = 8;
        backgroundColor = "#1e1e2eee";
        textColor = "#cdd6f4";
        borderColor = "#89b4fa";
        borderSize = 2;
      };
    };
  };
}

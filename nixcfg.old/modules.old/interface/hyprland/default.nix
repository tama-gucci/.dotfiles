{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.hyprland;
  username = config.modules.user.name;
  monitorsCfg = config.modules.monitors;
in
{
  # Note: Noctalia shell integration is handled by the noctalia.nix module
  # which injects keybinds and startup commands when enabled

  options.modules.hyprland = {
    enable = mkEnableOption "Hyprland window manager";
    
    autoLogin = mkOption {
      type = types.bool;
      default = true;
      description = "Auto-login the user and start Hyprland session";
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
  };

  config = mkIf cfg.enable {
    # System-level Hyprland
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    
    # Environment variables (system-wide)
    environment.sessionVariables = {
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_TYPE = "wayland";
      NIXOS_OZONE_WL = "1";
      XCURSOR_THEME = cfg.cursor.name;
      XCURSOR_SIZE = toString cfg.cursor.size;
    };
    
    # XDG portal for screen sharing, file dialogs
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    };

    # Auto-login with greetd
    services.greetd = mkIf cfg.autoLogin {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.hyprland}/bin/Hyprland";
          user = username;
        };
      };
    };
    
    # Cursor theme package
    environment.systemPackages = with pkgs; [
      bibata-cursors
      wl-clipboard
    ];

    # Home Manager Hyprland configuration
    home-manager.users.${username} = {
      # Cursor theme
      home.pointerCursor = {
        name = cfg.cursor.name;
        size = cfg.cursor.size;
        package = pkgs.bibata-cursors;
        gtk.enable = true;
        x11.enable = true;
      };
      
      wayland.windowManager.hyprland = {
        enable = true;
        xwayland.enable = true;
        systemd.enable = true;

        settings = {
          # Monitor configuration from modules.monitors or fallback to auto
          monitor = 
            if monitorsCfg.displays != [] 
            then monitorsCfg.hyprlandConfig
            else [ ",preferred,auto,1" ];

          # Cursor settings
          env = [
            "XCURSOR_THEME,${cfg.cursor.name}"
            "XCURSOR_SIZE,${toString cfg.cursor.size}"
          ];

          # Input
          input = {
            kb_layout = "us";
            follow_mouse = 1;
            sensitivity = 0;
            touchpad = {
              natural_scroll = true;
            };
          };

          # General
          general = {
            gaps_in = 5;
            gaps_out = 20;
            border_size = 2;
            "col.active_border" = "rgba(444444ff)";
            "col.inactive_border" = "rgba(222222ff)";
            layout = "dwindle";
          };

          # Decoration
          decoration = {
            rounding = 10;
            
            blur = {
              enabled = true;
              size = 3;
              passes = 1;
            };

            shadow = {
              enabled = true;
              range = 4;
              render_power = 3;
              color = "rgba(1a1a1aee)";
            };
          };

          # Animations
          animations = {
            enabled = true;
            bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
            animation = [
              "windows, 1, 7, myBezier"
              "windowsOut, 1, 7, default, popin 80%"
              "border, 1, 10, default"
              "borderangle, 1, 8, default"
              "fade, 1, 7, default"
              "workspaces, 1, 6, default"
            ];
          };

          # Dwindle layout
          dwindle = {
            pseudotile = true;
            preserve_split = true;
          };

          # Master layout
          master = {
            new_status = "master";
          };

          # Misc
          misc = {
            force_default_wallpaper = 0;
            disable_hyprland_logo = true;
          };

          # Render settings (HDR configuration)
          render = lib.optionalAttrs monitorsCfg.hdrEnabled {
            cm_auto_hdr = 1;
          };

          # Window rules
          windowrulev2 = [
            "opacity 0.0 override 0.0 override, class:^(xwaylandvideobridge)$"
            "noanim, class:^(xwaylandvideobridge)$"
            "nofocus, class:^(xwaylandvideobridge)$"
            "noinitialfocus, class:^(xwaylandvideobridge)$"
          ];

          # Mouse bindings
          bindm = [
            "SUPER, mouse:272, movewindow"
            "SUPER, mouse:273, resizewindow"
          ];

          # Key bindings
          bind = [
            # Window management
            "SUPER, Q, killactive,"
            "SUPER, M, exit,"
            "SUPER, V, togglefloating,"
            "SUPER, P, pseudo,"
            "SUPER, J, togglesplit,"
            
            # Applications
            "SUPER, Return, exec, ${cfg.terminal}"
            "SUPER, E, exec, ${cfg.fileManager}"
            # Note: Launcher (SUPER+Space) is configured by the shell module (e.g., Noctalia)
            
            # Focus navigation
            "SUPER, left, movefocus, l"
            "SUPER, right, movefocus, r"
            "SUPER, up, movefocus, u"
            "SUPER, down, movefocus, d"
            
            # Workspaces
            "SUPER, 1, workspace, 1"
            "SUPER, 2, workspace, 2"
            "SUPER, 3, workspace, 3"
            "SUPER, 4, workspace, 4"
            "SUPER, 5, workspace, 5"
            "SUPER, 6, workspace, 6"
            "SUPER, 7, workspace, 7"
            "SUPER, 8, workspace, 8"
            "SUPER, 9, workspace, 9"
            "SUPER, 0, workspace, 10"
            
            # Move to workspace
            "SUPER SHIFT, 1, movetoworkspace, 1"
            "SUPER SHIFT, 2, movetoworkspace, 2"
            "SUPER SHIFT, 3, movetoworkspace, 3"
            "SUPER SHIFT, 4, movetoworkspace, 4"
            "SUPER SHIFT, 5, movetoworkspace, 5"
            "SUPER SHIFT, 6, movetoworkspace, 6"
            "SUPER SHIFT, 7, movetoworkspace, 7"
            "SUPER SHIFT, 8, movetoworkspace, 8"
            "SUPER SHIFT, 9, movetoworkspace, 9"
            "SUPER SHIFT, 0, movetoworkspace, 10"
            
            # Special workspace
            "SUPER, S, togglespecialworkspace, magic"
            "SUPER SHIFT, S, movetoworkspace, special:magic"
            
            # Scroll through workspaces
            "SUPER, mouse_down, workspace, e+1"
            "SUPER, mouse_up, workspace, e-1"
          ];
        };
      };
    };
  };
}

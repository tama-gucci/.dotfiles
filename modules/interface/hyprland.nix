# ═══════════════════════════════════════════════════════════════════════════
# HYPRLAND WINDOW MANAGER MODULE
# ═══════════════════════════════════════════════════════════════════════════
# Hyprland compositor with NVIDIA optimizations and Noctalia shell integration
{ config, ... }:
let
  meta = config.flake.meta;
in
{
  # ─────────────────────────────────────────────────────────────────────────
  # NAMED MODULE EXPORT
  # ─────────────────────────────────────────────────────────────────────────
  flake.modules.nixos.hyprland = { config, pkgs, lib, ... }: {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    # Cursor configuration
    environment.sessionVariables = {
      XCURSOR_THEME = meta.defaults.cursor.name;
      XCURSOR_SIZE = toString meta.defaults.cursor.size;
    };

    # NVIDIA-specific environment variables
    environment.variables = lib.mkIf (config.hardware.nvidia.modesetting.enable or false) {
      LIBVA_DRIVER_NAME = "nvidia";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      NVD_BACKEND = "direct";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };

    # XDG Desktop Portal for screen sharing
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    };

    # Essential utilities
    environment.systemPackages = with pkgs; [
      wl-clipboard
      cliphist
      grimblast
      hyprpicker
      hypridle
      hyprlock
      swww
    ];

    # Home-manager Hyprland configuration
    home-manager.users.${meta.owner.username} = { pkgs, ... }: {
      wayland.windowManager.hyprland = {
        enable = true;
        systemd.enable = true;
        settings = {
          # General settings
          general = {
            gaps_in = 5;
            gaps_out = 10;
            border_size = 2;
            layout = "dwindle";
          };

          decoration = {
            rounding = 10;
            blur = {
              enabled = true;
              size = 3;
              passes = 1;
            };
            shadow = {
              enabled = false;
            };
          };

          animations = {
            enabled = true;
            bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
            animation = [
              "windows, 1, 7, myBezier"
              "windowsOut, 1, 7, default, popin 80%"
              "border, 1, 10, default"
              "fade, 1, 7, default"
              "workspaces, 1, 6, default"
            ];
          };

          dwindle = {
            pseudotile = true;
            preserve_split = true;
          };

          input = {
            follow_mouse = 1;
            sensitivity = 0;
            touchpad = {
              natural_scroll = true;
            };
          };

          misc = {
            force_default_wallpaper = 0;
            disable_hyprland_logo = true;
          };

          # Keybindings
          "$mod" = "SUPER";
          bind = [
            "$mod, Return, exec, ${meta.defaults.terminal}"
            "$mod, Q, killactive"
            "$mod, M, exit"
            "$mod, E, exec, ${meta.defaults.fileManager}"
            "$mod, V, togglefloating"
            "$mod, D, exec, rofi -show drun"
            "$mod, F, fullscreen"
            
            # Window navigation
            "$mod, H, movefocus, l"
            "$mod, L, movefocus, r"
            "$mod, K, movefocus, u"
            "$mod, J, movefocus, d"
            
            # Workspaces
            "$mod, 1, workspace, 1"
            "$mod, 2, workspace, 2"
            "$mod, 3, workspace, 3"
            "$mod, 4, workspace, 4"
            "$mod, 5, workspace, 5"
            "$mod, 6, workspace, 6"
            "$mod, 7, workspace, 7"
            "$mod, 8, workspace, 8"
            "$mod, 9, workspace, 9"
            "$mod, 0, workspace, 10"
            
            # Move to workspace
            "$mod SHIFT, 1, movetoworkspace, 1"
            "$mod SHIFT, 2, movetoworkspace, 2"
            "$mod SHIFT, 3, movetoworkspace, 3"
            "$mod SHIFT, 4, movetoworkspace, 4"
            "$mod SHIFT, 5, movetoworkspace, 5"
            "$mod SHIFT, 6, movetoworkspace, 6"
            "$mod SHIFT, 7, movetoworkspace, 7"
            "$mod SHIFT, 8, movetoworkspace, 8"
            "$mod SHIFT, 9, movetoworkspace, 9"
            "$mod SHIFT, 0, movetoworkspace, 10"
            
            # Screenshot
            ", Print, exec, grimblast copy area"
            "SHIFT, Print, exec, grimblast copy screen"
          ];

          bindm = [
            "$mod, mouse:272, movewindow"
            "$mod, mouse:273, resizewindow"
          ];
        };
      };
    };
  };
}

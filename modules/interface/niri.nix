# ═══════════════════════════════════════════════════════════════════════════
# NIRI WINDOW MANAGER MODULE
# ═══════════════════════════════════════════════════════════════════════════
# Niri scrolling compositor with NVIDIA support and modern Wayland features
{ config, inputs, ... }:
let
  meta = config.flake.meta;
in
{
  # ─────────────────────────────────────────────────────────────────────────
  # NAMED MODULE EXPORT
  # ─────────────────────────────────────────────────────────────────────────
  flake.modules.nixos.niri = { config, pkgs, lib, ... }: {
    imports = [ inputs.niri.nixosModules.niri ];

    programs.niri = {
      enable = true;
      # Disable tests to avoid "Too many open files" error during Nix build
      # See: https://github.com/sodiboo/niri-flake (niri tests can fail in sandboxed builds)
      package = inputs.niri.packages.${pkgs.system}.niri-stable.overrideAttrs (_: {
        doCheck = false;
      });
    };

    # XDG Desktop Portal
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    };

    # NVIDIA environment variables
    environment.variables = lib.mkIf (config.hardware.nvidia.modesetting.enable or false) {
      LIBVA_DRIVER_NAME = "nvidia";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      NVD_BACKEND = "direct";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };

    # Cursor configuration
    environment.sessionVariables = {
      XCURSOR_THEME = meta.defaults.cursor.name;
      XCURSOR_SIZE = toString meta.defaults.cursor.size;
    };

    # Essential utilities
    environment.systemPackages = with pkgs; [
      wl-clipboard
      cliphist
      swww
      fuzzel
      grim
      slurp
    ];

    # Home-manager Niri configuration
    home-manager.users.${meta.owner.username} = { pkgs, ... }: {
      programs.niri = {
        settings = {
          # Input configuration
          input = {
            keyboard = {
              xkb = {
                layout = "us";
              };
            };
            touchpad = {
              tap = true;
              natural-scroll = true;
            };
            mouse = {
              accel-profile = "flat";
            };
          };

          # Layout
          layout = {
            gaps = 10;
            center-focused-column = "never";
            preset-column-widths = [
              { proportion = 1.0 / 3.0; }
              { proportion = 1.0 / 2.0; }
              { proportion = 2.0 / 3.0; }
            ];
            default-column-width = { proportion = 1.0 / 2.0; };
            focus-ring = {
              enable = true;
              width = 2;
            };
            border = {
              enable = false;
            };
          };

          # Animations
          animations = {
            enable = true;
          };

          # Misc
          prefer-no-csd = true;
          screenshot-path = "~/Pictures/Screenshots/%Y-%m-%d_%H-%M-%S.png";

          # Spawn at startup
          spawn-at-startup = [
            { argv = [ "swww-daemon" ]; }
          ];

          # Keybindings
          binds = let
            mod = "Mod";
          in {
            "${mod}+Return".action.spawn = [ meta.defaults.terminal ];
            "${mod}+D".action.spawn = [ "fuzzel" ];
            "${mod}+E".action.spawn = [ meta.defaults.fileManager ];
            
            "${mod}+Q".action.close-window = {};
            "${mod}+Shift+E".action.quit = {};
            "${mod}+Shift+Slash".action.show-hotkey-overlay = {};
            
            # Focus
            "${mod}+H".action.focus-column-left = {};
            "${mod}+J".action.focus-window-down = {};
            "${mod}+K".action.focus-window-up = {};
            "${mod}+L".action.focus-column-right = {};
            
            # Move
            "${mod}+Shift+H".action.move-column-left = {};
            "${mod}+Shift+J".action.move-window-down = {};
            "${mod}+Shift+K".action.move-window-up = {};
            "${mod}+Shift+L".action.move-column-right = {};
            
            # Workspace
            "${mod}+1".action.focus-workspace = 1;
            "${mod}+2".action.focus-workspace = 2;
            "${mod}+3".action.focus-workspace = 3;
            "${mod}+4".action.focus-workspace = 4;
            "${mod}+5".action.focus-workspace = 5;
            "${mod}+6".action.focus-workspace = 6;
            "${mod}+7".action.focus-workspace = 7;
            "${mod}+8".action.focus-workspace = 8;
            "${mod}+9".action.focus-workspace = 9;
            
            # Move to workspace
            "${mod}+Shift+1".action.move-column-to-workspace = 1;
            "${mod}+Shift+2".action.move-column-to-workspace = 2;
            "${mod}+Shift+3".action.move-column-to-workspace = 3;
            "${mod}+Shift+4".action.move-column-to-workspace = 4;
            "${mod}+Shift+5".action.move-column-to-workspace = 5;
            "${mod}+Shift+6".action.move-column-to-workspace = 6;
            "${mod}+Shift+7".action.move-column-to-workspace = 7;
            "${mod}+Shift+8".action.move-column-to-workspace = 8;
            "${mod}+Shift+9".action.move-column-to-workspace = 9;
            
            # Layout
            "${mod}+F".action.maximize-column = {};
            "${mod}+Shift+F".action.fullscreen-window = {};
            "${mod}+V".action.toggle-window-floating = {};
            "${mod}+Minus".action.set-column-width = "-10%";
            "${mod}+Equal".action.set-column-width = "+10%";
            
            # Screenshot
            "Print".action.screenshot = {};
            "Shift+Print".action.screenshot-screen = {};
            "${mod}+Print".action.screenshot-window = {};
          };
        };
      };
    };
  };
}

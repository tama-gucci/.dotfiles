# ═══════════════════════════════════════════════════════════════════════════
# NIRI WINDOW MANAGER MODULE
# ═══════════════════════════════════════════════════════════════════════════
# Niri scrolling compositor with NVIDIA support and modern Wayland features
# NOTE: This module requires niri to be available in nixpkgs. For the full
# home-manager integration, consider adding the niri flake as an input.
{ lib, config, ... }:
let
  meta = config.flake.meta;
in
{
  # ─────────────────────────────────────────────────────────────────────────
  # NAMED MODULE EXPORT
  # ─────────────────────────────────────────────────────────────────────────
  flake.modules.nixos.niri = { config, pkgs, lib, ... }: {
    # Install niri as a package (programs.niri is not a NixOS option)
    environment.systemPackages = with pkgs; [
      niri
      wl-clipboard
      cliphist
      swww
      fuzzel
      grim
      slurp
    ];

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

    # Home-manager Niri configuration (using xdg.configFile instead of programs.niri)
    home-manager.users.${meta.owner.username} = { pkgs, ... }: {
      # Write niri config file directly
      xdg.configFile."niri/config.kdl".text = ''
        // Input configuration
        input {
            keyboard {
                xkb {
                    layout "us"
                }
            }
            touchpad {
                tap
                natural-scroll
            }
            mouse {
                accel-profile "flat"
            }
        }

        // Layout
        layout {
            gaps 10
            center-focused-column "never"
            
            preset-column-widths {
                proportion 0.33333
                proportion 0.5
                proportion 0.66667
            }
            
            default-column-width { proportion 0.5; }
            
            focus-ring {
                width 2
            }
        }

        // Animations
        animations {
        }

        // Misc
        prefer-no-csd

        screenshot-path "~/Pictures/Screenshots/%Y-%m-%d_%H-%M-%S.png"

        // Spawn at startup
        spawn-at-startup "swww-daemon"

        // Keybindings
        binds {
            Mod+Return { spawn "${meta.defaults.terminal}"; }
            Mod+D { spawn "fuzzel"; }
            Mod+E { spawn "${meta.defaults.fileManager}"; }
            
            Mod+Q { close-window; }
            Mod+Shift+E { quit; }
            Mod+Shift+Slash { show-hotkey-overlay; }
            
            // Focus
            Mod+H { focus-column-left; }
            Mod+J { focus-window-down; }
            Mod+K { focus-window-up; }
            Mod+L { focus-column-right; }
            
            // Move
            Mod+Shift+H { move-column-left; }
            Mod+Shift+J { move-window-down; }
            Mod+Shift+K { move-window-up; }
            Mod+Shift+L { move-column-right; }
            
            // Workspace
            Mod+1 { focus-workspace 1; }
            Mod+2 { focus-workspace 2; }
            Mod+3 { focus-workspace 3; }
            Mod+4 { focus-workspace 4; }
            Mod+5 { focus-workspace 5; }
            Mod+6 { focus-workspace 6; }
            Mod+7 { focus-workspace 7; }
            Mod+8 { focus-workspace 8; }
            Mod+9 { focus-workspace 9; }
            
            // Move to workspace
            Mod+Shift+1 { move-column-to-workspace 1; }
            Mod+Shift+2 { move-column-to-workspace 2; }
            Mod+Shift+3 { move-column-to-workspace 3; }
            Mod+Shift+4 { move-column-to-workspace 4; }
            Mod+Shift+5 { move-column-to-workspace 5; }
            Mod+Shift+6 { move-column-to-workspace 6; }
            Mod+Shift+7 { move-column-to-workspace 7; }
            Mod+Shift+8 { move-column-to-workspace 8; }
            Mod+Shift+9 { move-column-to-workspace 9; }
            
            // Layout
            Mod+F { maximize-column; }
            Mod+Shift+F { fullscreen-window; }
            Mod+V { toggle-window-floating; }
            Mod+Minus { set-column-width "-10%"; }
            Mod+Equal { set-column-width "+10%"; }
            
            // Screenshot
            Print { screenshot; }
            Shift+Print { screenshot-screen; }
            Mod+Print { screenshot-window; }
        }
      '';
    };
  };
}

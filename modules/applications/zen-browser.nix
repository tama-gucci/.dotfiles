# ═══════════════════════════════════════════════════════════════════════════
# ZEN BROWSER MODULE
# ═══════════════════════════════════════════════════════════════════════════
# Zen Browser - privacy-focused Firefox fork
{ config, inputs, ... }:
let
  meta = config.flake.meta;
in
{
  # ─────────────────────────────────────────────────────────────────────────
  # NAMED MODULE EXPORT
  # ─────────────────────────────────────────────────────────────────────────
  flake.modules.nixos.zen-browser = { config, pkgs, ... }: {
    # Install Zen Browser from flake input
    environment.systemPackages = [
      inputs.zen-browser.packages.${pkgs.system}.default
    ];

    # Set as default browser
    environment.sessionVariables = {
      BROWSER = "zen";
    };

    # XDG MIME associations
    xdg.mime.defaultApplications = {
      "text/html" = "zen.desktop";
      "x-scheme-handler/http" = "zen.desktop";
      "x-scheme-handler/https" = "zen.desktop";
      "x-scheme-handler/about" = "zen.desktop";
      "x-scheme-handler/unknown" = "zen.desktop";
    };

    # User-level configuration
    home-manager.users.${meta.owner.username} = { ... }: {
      # Ensure Zen is the default browser
      home.sessionVariables.BROWSER = "zen";
      
      # XDG user-level defaults
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "text/html" = [ "zen.desktop" ];
          "x-scheme-handler/http" = [ "zen.desktop" ];
          "x-scheme-handler/https" = [ "zen.desktop" ];
        };
      };
    };
  };
}

# ═══════════════════════════════════════════════════════════════════════════
# NIX SETTINGS
# ═══════════════════════════════════════════════════════════════════════════
# Nix daemon configuration applied to all systems
{ lib, config, ... }:
let
  # Shared Nix settings for all configuration types
  nixSettings = {
    # Enable modern CLI and flakes
    experimental-features = [ "nix-command" "flakes" ];
    
    # Performance
    max-jobs = "auto";
    auto-optimise-store = true;
    
    # Don't warn about dirty git repos
    warn-dirty = false;
  };
in
{
  flake.modules = {
    # ─────────────────────────────────────────────────────────────────────────
    # NIXOS
    # ─────────────────────────────────────────────────────────────────────────
    nixos.base = {
      nix = {
        settings = nixSettings;
        
        # Garbage collection
        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 30d";
        };
      };
      
      # Allow unfree packages
      nixpkgs.config.allowUnfree = true;
    };
    
    # ─────────────────────────────────────────────────────────────────────────
    # HOME MANAGER
    # ─────────────────────────────────────────────────────────────────────────
    homeManager.base = {
      nix.settings = nixSettings;
    };
  };
}

# ═══════════════════════════════════════════════════════════════════════════
# NIX SETTINGS
# ═══════════════════════════════════════════════════════════════════════════
# Nix daemon configuration applied to all systems
# NOTE: NixOS nix settings are now in modules/nixos/base.nix
# This file only provides home-manager base settings
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
    # HOME MANAGER
    # ─────────────────────────────────────────────────────────────────────────
    homeManager.base = {
      nix.settings = nixSettings;
    };
  };
}

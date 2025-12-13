# ═══════════════════════════════════════════════════════════════════════════
# METADATA
# ═══════════════════════════════════════════════════════════════════════════
# Defines owner information and constants used across the configuration
# Access via: config.flake.meta.owner, config.flake.meta.defaults
{ lib, ... }:
{
  options.flake.meta = lib.mkOption {
    type = lib.types.anything;
    description = "Flake metadata: owner info, constants, defaults";
  };

  config.flake.meta = {
    # ─────────────────────────────────────────────────────────────────────────
    # OWNER INFO
    # ─────────────────────────────────────────────────────────────────────────
    owner = {
      username = "sin";
      name = "Sin";
      email = "sinclair.rivera@gmail.com";
    };
    
    # ─────────────────────────────────────────────────────────────────────────
    # SYSTEM DEFAULTS
    # Centralized defaults - change once, applies everywhere
    # ─────────────────────────────────────────────────────────────────────────
    defaults = {
      # Shell
      shell = "fish";
      
      # Editors
      editor = "nvim";
      terminal = "kitty";
      fileManager = "nautilus";
      
      # Locale
      timezone = "America/New_York";
      locale = "en_US.UTF-8";
      keyboardLayout = "us";
      
      # Cursor
      cursor = {
        name = "Bibata-Modern-Classic";
        size = 24;
      };
      
      # Git
      git = {
        defaultBranch = "main";
      };
      
      # NixOS state version
      stateVersion = "25.11";
    };
  };
}

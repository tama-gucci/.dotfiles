# ═══════════════════════════════════════════════════════════════════════════
# NIXOS BASE MODULE
# ═══════════════════════════════════════════════════════════════════════════
# The foundation module that ALL NixOS systems inherit
# Contains: boot, security, essential packages
{ config, inputs, ... }:
let
  meta = config.flake.meta;
in
{
  flake.modules.nixos.base = { pkgs, lib, ... }: {
    # ─────────────────────────────────────────────────────────────────────────
    # BOOT
    # ─────────────────────────────────────────────────────────────────────────
    boot.loader = {
      efi.canTouchEfiVariables = true;
      # systemd-boot is default; lanzaboote overrides for secure boot
      systemd-boot.enable = lib.mkDefault true;
    };
    
    # ─────────────────────────────────────────────────────────────────────────
    # SECURITY
    # ─────────────────────────────────────────────────────────────────────────
    security = {
      sudo.enable = true;
      polkit.enable = true;
    };
    
    # ─────────────────────────────────────────────────────────────────────────
    # NETWORKING
    # ─────────────────────────────────────────────────────────────────────────
    networking = {
      networkmanager.enable = true;
      firewall.enable = true;
    };
    
    # ─────────────────────────────────────────────────────────────────────────
    # LOCALE (from meta.defaults)
    # ─────────────────────────────────────────────────────────────────────────
    time.timeZone = lib.mkDefault meta.defaults.timezone;
    i18n.defaultLocale = lib.mkDefault meta.defaults.locale;
    
    # ─────────────────────────────────────────────────────────────────────────
    # NIX SETTINGS
    # ─────────────────────────────────────────────────────────────────────────
    nix = {
      settings = {
        experimental-features = [ "nix-command" "flakes" ];
        max-jobs = "auto";
        auto-optimise-store = true;
        warn-dirty = false;
      };
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
    };
    
    nixpkgs.config.allowUnfree = true;
    
    # ─────────────────────────────────────────────────────────────────────────
    # ESSENTIAL PACKAGES
    # ─────────────────────────────────────────────────────────────────────────
    environment.systemPackages = with pkgs; [
      curl
      wget
      vim
      git
      yazi
    ];
    
    # ─────────────────────────────────────────────────────────────────────────
    # STATE VERSION
    # ─────────────────────────────────────────────────────────────────────────
    system.stateVersion = lib.mkDefault meta.defaults.stateVersion;
  };
}


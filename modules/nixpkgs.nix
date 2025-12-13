# ═══════════════════════════════════════════════════════════════════════════
# NIXPKGS CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════
# Configures nixpkgs: overlays, unfree packages, per-system pkgs instance
{ lib, config, inputs, ... }:
{
  # ─────────────────────────────────────────────────────────────────────────
  # OPTIONS
  # ─────────────────────────────────────────────────────────────────────────
  options.nixpkgs = {
    config = {
      allowUnfreePredicate = lib.mkOption {
        type = lib.types.functionTo lib.types.bool;
        default = _: true;  # Allow all unfree packages
        description = "Predicate for allowing unfree packages";
      };
    };
    overlays = lib.mkOption {
      type = lib.types.listOf lib.types.unspecified;
      default = [];
      description = "Nixpkgs overlays to apply";
    };
  };

  # ─────────────────────────────────────────────────────────────────────────
  # PER-SYSTEM CONFIGURATION
  # ─────────────────────────────────────────────────────────────────────────
  config.perSystem = { system, ... }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        inherit (config.nixpkgs.config) allowUnfreePredicate;
      };
      inherit (config.nixpkgs) overlays;
    };
  };
}

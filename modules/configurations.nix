# ═══════════════════════════════════════════════════════════════════════════
# NIXOS CONFIGURATIONS
# ═══════════════════════════════════════════════════════════════════════════
# Defines the `configurations.nixos` option and evaluates them into
# `flake.nixosConfigurations` outputs
{ lib, config, inputs, ... }:
{
  # ─────────────────────────────────────────────────────────────────────────
  # OPTIONS
  # ─────────────────────────────────────────────────────────────────────────
  options.configurations.nixos = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      lib.types.submodule {
        options = {
          system = lib.mkOption {
            type = lib.types.str;
            default = "x86_64-linux";
            description = "System architecture";
          };
          modules = lib.mkOption {
            type = lib.types.listOf lib.types.deferredModule;
            default = [];
            description = "List of NixOS modules for this configuration";
          };
        };
      }
    );
    default = {};
    description = "NixOS configurations to build";
  };

  # ─────────────────────────────────────────────────────────────────────────
  # CONFIG
  # ─────────────────────────────────────────────────────────────────────────
  config.flake = {
    # Build nixosConfigurations from configurations.nixos
    nixosConfigurations = lib.mapAttrs (
      name: { system, modules }:
      lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = modules ++ [
          inputs.home-manager.nixosModules.home-manager
          inputs.chaotic.nixosModules.default
          inputs.lanzaboote.nixosModules.lanzaboote
        ];
      }
    ) config.configurations.nixos;

    # Add configurations as checks
    checks = lib.pipe config.flake.nixosConfigurations [
      (lib.mapAttrsToList (name: nixos: {
        ${nixos.config.nixpkgs.hostPlatform.system} = {
          "nixos/${name}" = nixos.config.system.build.toplevel;
        };
      }))
      lib.mkMerge
    ];
  };
}

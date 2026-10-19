{
  description = "NixOS System Configuration - Dendritic Pattern";

  # ═══════════════════════════════════════════════════════════════════════════
  # INPUTS
  # ═══════════════════════════════════════════════════════════════════════════
  inputs = {
    # Core
    chrysalis.url = "github:tama-gucci/chrysalis/79961a0855cfb0407ff6cb7a84fdcbf3630e5b90";
    nixpkgs.follows = "chrysalis/nixpkgs";

    # Flake infrastructure
    flake-parts = {
      follows = "chrysalis/flake-parts";
    };
    import-tree.follows = "chrysalis/import-tree";

    # Home manager
    home-manager = {
      follows = "chrysalis/home-manager";
    };

    # Hardware support
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Desktop environment
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Applications
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # OUTPUTS
  # ═══════════════════════════════════════════════════════════════════════════
  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      imports = [ (inputs.import-tree ./modules) ];
    };

  # ═══════════════════════════════════════════════════════════════════════════
  # NIX CONFIGURATION
  # ═══════════════════════════════════════════════════════════════════════════
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
}

{
  description = "NixOS System Configuration - Dendritic Pattern";

  # ═══════════════════════════════════════════════════════════════════════════
  # INPUTS
  # ═══════════════════════════════════════════════════════════════════════════
  inputs = {
    # Core
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    # Flake infrastructure
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    import-tree.url = "github:vic/import-tree";
    
    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Hardware support
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Kernels and packages
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    
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
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];
      imports = [ (inputs.import-tree ./modules) ];
    };

  # ═══════════════════════════════════════════════════════════════════════════
  # NIX CONFIGURATION
  # ═══════════════════════════════════════════════════════════════════════════
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://chaotic-nyx.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
    ];
  };
}


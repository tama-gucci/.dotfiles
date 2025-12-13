{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.development;
in
{
  options.modules.development = {
    enable = mkEnableOption "Development tools and environment";
    
    languages = {
      python = mkEnableOption "Python development";
      javascript = mkEnableOption "JavaScript/Node.js development";
      rust = mkEnableOption "Rust development";
      go = mkEnableOption "Go development";
      c = mkEnableOption "C/C++ development";
      nix = mkEnableOption "Nix development" // { default = true; };
    };
    
    editors = {
      vscode = mkEnableOption "Visual Studio Code";
      neovim = mkEnableOption "Neovim with development plugins" // { default = true; };
      zed = mkEnableOption "Zed editor";
    };
    
    containers = mkEnableOption "Docker and container tools";
    
    databases = mkEnableOption "Database clients and tools";
  };

  config = mkIf cfg.enable {
    # Ensure git module is enabled for development
    modules.git.enable = true;
    
    # Core development tools (always included)
    environment.systemPackages = with pkgs;
      [
        # Build essentials
        gnumake
        cmake
        pkg-config
        
        # Terminal utilities
        ripgrep               # Fast grep (rg)
        fd                    # Fast find
        fzf                   # Fuzzy finder
        jq                    # JSON processor
        yq                    # YAML processor
        tree                  # Directory listing
        httpie                # Modern HTTP client
        
        # File management
        zip
        p7zip
        
        # Process management
        btop
        
        # Networking
        nmap
        dig
      ]
      
      # Nix development
      ++ optionals cfg.languages.nix [
        nil                   # Nix LSP
        nixfmt-rfc-style      # Nix formatter
        nix-tree              # Dependency viewer
        nix-diff              # Compare derivations
        statix                # Nix linter
        deadnix               # Dead code finder
      ]
      
      # Python
      ++ optionals cfg.languages.python [
        python3
        python3Packages.pip
        python3Packages.virtualenv
        python3Packages.ipython
        ruff                  # Fast Python linter/formatter
        pyright               # Python LSP
      ]
      
      # JavaScript/Node.js
      ++ optionals cfg.languages.javascript [
        nodejs
        nodePackages.npm
        nodePackages.pnpm
        nodePackages.yarn
        nodePackages.typescript
        nodePackages.typescript-language-server
        deno
        bun
      ]
      
      # Rust
      ++ optionals cfg.languages.rust [
        rustup                # Rust toolchain manager
        rust-analyzer         # Rust LSP
        cargo-watch           # Auto-rebuild on changes
        cargo-edit            # Cargo add/rm/upgrade
      ]
      
      # Go
      ++ optionals cfg.languages.go [
        go
        gopls                 # Go LSP
        golangci-lint         # Go linter
        delve                 # Go debugger
      ]
      
      # C/C++
      ++ optionals cfg.languages.c [
        gcc
        clang
        clang-tools           # clangd, clang-format
        gdb
        lldb
        valgrind
      ]
      
      # Editors
      ++ optionals cfg.editors.vscode [
        vscode
      ]
      
      ++ optionals cfg.editors.neovim [
        neovim
        tree-sitter           # Parser for syntax highlighting
      ]
      
      ++ optionals cfg.editors.zed [
        zed-editor
      ]
      
      # Containers
      ++ optionals cfg.containers [
        docker-compose
        lazydocker            # Terminal UI for Docker
        dive                  # Explore Docker images
        podman
        podman-compose
      ]
      
      # Databases
      ++ optionals cfg.databases [
        dbeaver-bin           # Universal database GUI
        postgresql            # PostgreSQL client (psql)
        sqlite
        redis
      ];
    
    # Docker daemon (if containers enabled)
    virtualisation.docker = mkIf cfg.containers {
      enable = true;
      enableOnBoot = false;   # Start on-demand to save resources
    };
    
    # Add user to docker group
    users.users.${config.modules.user.name}.extraGroups = 
      mkIf cfg.containers [ "docker" ];
  };
}

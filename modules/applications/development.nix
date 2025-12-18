# ═══════════════════════════════════════════════════════════════════════════
# DEVELOPMENT MODULE
# ═══════════════════════════════════════════════════════════════════════════
# Development tools, editors, and language support
{ config, ... }:
let
  meta = config.flake.meta;
in
{
  # ─────────────────────────────────────────────────────────────────────────
  # NAMED MODULE EXPORT
  # ─────────────────────────────────────────────────────────────────────────
  flake.modules.nixos.development = { config, pkgs, ... }: {
    # Essential development packages
    environment.systemPackages = with pkgs; [
      # Editors
      neovim
      helix
      
      # Version control
      git
      gh
      lazygit
      
      # Build tools
      gnumake
      cmake
      meson
      ninja
      
      # Languages & runtimes
      rustup
      go
      nodejs
      python3
      
      # Language servers
      nil # Nix
      rust-analyzer
      gopls
      nodePackages.typescript-language-server
      pyright
      
      # Containers
      podman
      distrobox
      
      # Utilities
      jq
      yq
      ripgrep
      fd
      bat
      eza
      fzf
      zoxide
      direnv
      
      # Nix tools
      alejandra
      nixd
      nix-tree
      nix-diff
    ];

    # Enable Docker/Podman
    virtualisation = {
      podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
      };
    };

    # Direnv for automatic environment switching
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # User development setup via home-manager
    home-manager.users.${meta.owner.username} = { pkgs, ... }: {
      # Neovim as default editor
      home.sessionVariables = {
        EDITOR = meta.defaults.editor;
        VISUAL = meta.defaults.editor;
      };

      # Git configuration
      programs.git = {
        enable = true;
        userName = meta.owner.name;
        userEmail = meta.owner.email;
        
        extraConfig = {
          init.defaultBranch = "main";
          pull.rebase = true;
          push.autoSetupRemote = true;
          
          diff.algorithm = "histogram";
          merge.conflictstyle = "zdiff3";
          
          rerere.enabled = true;
          column.ui = "auto";
          branch.sort = "-committerdate";
        };
        
        delta = {
          enable = true;
          options = {
            navigate = true;
            side-by-side = true;
            line-numbers = true;
          };
        };
      };

      # Lazygit config
      programs.lazygit = {
        enable = true;
        settings = {
          gui = {
            showRandomTip = false;
            nerdFontsVersion = "3";
          };
        };
      };

      # Zoxide for smart cd
      programs.zoxide = {
        enable = true;
        enableFishIntegration = true;
      };

      # Bat for syntax-highlighted cat
      programs.bat = {
        enable = true;
        config = {
          theme = "Catppuccin Mocha";
        };
      };

      # Fzf for fuzzy finding
      programs.fzf = {
        enable = true;
        enableFishIntegration = true;
        colors = {
          bg = "#1e1e2e";
          "bg+" = "#313244";
          fg = "#cdd6f4";
          "fg+" = "#cdd6f4";
          hl = "#f38ba8";
          "hl+" = "#f38ba8";
          header = "#f38ba8";
          info = "#cba6f7";
          marker = "#f5e0dc";
          pointer = "#f5e0dc";
          prompt = "#cba6f7";
          spinner = "#f5e0dc";
        };
      };
    };
  };
}

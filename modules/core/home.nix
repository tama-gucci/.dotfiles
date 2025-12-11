{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.modules.user;
in
{
  options.modules.user = {
    name = mkOption {
      type = types.str;
      default = "user";
      description = "Primary user account name";
    };
    
    packages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "User-specific packages";
    };
    
    sudoNoPassword = mkOption {
      type = types.bool;
      default = false;
      description = "Allow sudo without entering password";
    };
    
    shell = mkOption {
      type = types.enum [ "bash" "fish" "zsh" ];
      default = "bash";
      description = "User's default shell";
    };
    
    desktop = mkOption {
      type = types.bool;
      default = true;
      description = "Enable desktop environment features (GUI apps, theming, fonts)";
    };
    
    editor = mkOption {
      type = types.str;
      default = "nvim";
      description = "Default editor";
    };
  };

  config = {
    # User account
    users.users.${cfg.name} = {
      isNormalUser = true;
      home = "/home/${cfg.name}";
      extraGroups = [ "wheel" "networkmanager" ];
      initialPassword = "changeme";
      shell = {
        bash = pkgs.bash;
        fish = pkgs.fish;
        zsh = pkgs.zsh;
      }.${cfg.shell};
    };
    
    # Enable the chosen shell system-wide
    programs.fish.enable = cfg.shell == "fish";
    programs.zsh.enable = cfg.shell == "zsh";
    
    # Passwordless sudo for user
    security.sudo.extraRules = mkIf cfg.sudoNoPassword [
      {
        users = [ cfg.name ];
        commands = [
          {
            command = "ALL";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
    
    # Desktop packages and fonts
    environment.systemPackages = mkIf cfg.desktop (with pkgs; [
      pavucontrol
    ]);
    
    fonts.packages = mkIf cfg.desktop (with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-color-emoji
    ]);
    
    # Home Manager configuration
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      
      users.${cfg.name} = { config, ... }: {
        _module.args = { inherit inputs; };
        programs.home-manager.enable = true;
        
        home = {
          username = cfg.name;
          homeDirectory = "/home/${cfg.name}";
          stateVersion = "25.11";
          packages = with pkgs; cfg.packages ++ [
            # Base CLI tools for all users
            btop
            fastfetch
            unzip
            yazi
          ];
        };
        
        # Shell configuration
        programs.fish = mkIf (cfg.shell == "fish") {
          enable = true;
          interactiveShellInit = ''
            set -g fish_greeting
          '';
        };
        
        programs.zsh = mkIf (cfg.shell == "zsh") {
          enable = true;
          autosuggestion.enable = true;
          syntaxHighlighting.enable = true;
        };
        
        # Starship prompt (works with all shells)
        programs.starship = {
          enable = true;
          enableFishIntegration = cfg.shell == "fish";
          enableZshIntegration = cfg.shell == "zsh";
          enableBashIntegration = cfg.shell == "bash";
        };
        
        # Neovim
        programs.neovim = {
          enable = true;
          defaultEditor = cfg.editor == "nvim";
          viAlias = true;
          vimAlias = true;
        };
        
        # Direnv for per-project environments
        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
        
        # Desktop-only configuration
        programs.kitty = mkIf cfg.desktop {
          enable = true;
        };
        
        gtk = mkIf cfg.desktop {
          enable = true;
          theme.name = "Adwaita-dark";
          iconTheme = {
            name = "Papirus-Dark";
            package = pkgs.papirus-icon-theme;
          };
        };
        
        xdg = mkIf cfg.desktop {
          enable = true;
          userDirs = {
            enable = true;
            createDirectories = true;
          };
        };
      };
    };
  };
}

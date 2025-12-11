{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.profiles.sin;
in
{
  options.modules.profiles.sin = {
    enable = mkEnableOption "Sin's user profile";
  };

  config = mkIf cfg.enable {
    # User account settings
    modules.user = {
      name = "sin";
      shell = "fish";
      sudoNoPassword = true;
      desktop = true;
      editor = "nvim";
      packages = with pkgs; [
        google-chrome
        nautilus
        mpv
      ];
    };
    
    # Git configuration for sin
    modules.git = {
      enable = true;
      userName = "Sinclair";
      userEmail = "sinclair.rivera@gmail.com";  # Set your email here
      defaultBranch = "main";
      editor = "nvim";
    };
    
    # Additional home-manager configuration specific to sin
    home-manager.users.sin = {
      # Fish shell customizations
      programs.fish.shellAliases = {
        # Custom aliases for sin
        dotfiles = "cd ~/.dotfiles";
        conf = "cd ~/.dotfiles && nvim .";
        
        # NixOS management
        rebuild = "sudo nixos-rebuild switch --flake ~/.dotfiles#${config.networking.hostName}";
        update = "nix flake update ~/.dotfiles && sudo nixos-rebuild switch --flake ~/.dotfiles#${config.networking.hostName}";
        clean = "sudo nix-collect-garbage -d";
        
        # Quick shortcuts
        ll = "ls -la";
        ".." = "cd ..";
        "..." = "cd ../..";
        
        # Git shortcuts
        g = "git";
        gs = "git status -sb";
        ga = "git add";
        gc = "git commit";
        gp = "git push";
        gl = "git pull";
        gd = "git diff";
        gco = "git checkout";
        gb = "git branch";
        glg = "lazygit";
      };
      
      # Starship prompt customization
      programs.starship.settings = {
        add_newline = false;
        
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[✗](bold red)";
        };
        
        directory = {
          truncation_length = 3;
          truncate_to_repo = true;
        };
        
        git_branch = {
          symbol = " ";
          style = "bold purple";
        };
        
        git_status = {
          style = "bold red";
        };
        
        nix_shell = {
          symbol = " ";
          style = "bold blue";
        };
        
        hostname = {
          ssh_only = true;
          format = "[$hostname]($style) ";
        };
      };
      
      # Kitty terminal customization (override defaults)
      programs.kitty.settings = lib.mkForce {
        font_family = "JetBrainsMono Nerd Font";
        font_size = 12;
        background_opacity = "0.92";
        confirm_os_window_close = 0;
        enable_audio_bell = false;
        cursor_shape = "beam";
        cursor_blink_interval = 0;
        scrollback_lines = 10000;
        copy_on_select = true;
        
        # Window settings
        window_padding_width = 8;
        hide_window_decorations = false;
      };
    };
  };
}

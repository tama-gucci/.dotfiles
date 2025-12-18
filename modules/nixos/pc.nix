# ═══════════════════════════════════════════════════════════════════════════
# NIXOS PC MODULE
# ═══════════════════════════════════════════════════════════════════════════
# Common configuration for personal computers (desktops and laptops)
# Inherits: base
# Contains: audio, bluetooth, graphics, fonts, user setup
{ config, inputs, ... }:
let
  meta = config.flake.meta;
  inherit (config.flake.modules.nixos) base;
in
{
  flake.modules.nixos.pc = { pkgs, lib, config, ... }: {
    imports = [ base ];
    
    # ─────────────────────────────────────────────────────────────────────────
    # USER ACCOUNT
    # ─────────────────────────────────────────────────────────────────────────
    users.users.${meta.owner.username} = {
      isNormalUser = true;
      home = "/home/${meta.owner.username}";
      extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
      initialPassword = "changeme";
      shell = pkgs.${meta.defaults.shell};
    };
    
    # Enable the shell system-wide
    programs.${meta.defaults.shell}.enable = true;
    
    # Passwordless sudo for owner
    security.sudo.extraRules = [{
      users = [ meta.owner.username ];
      commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
    }];
    
    # ─────────────────────────────────────────────────────────────────────────
    # AUDIO (PipeWire)
    # ─────────────────────────────────────────────────────────────────────────
    services.pulseaudio.enable = false;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };
    
    # ─────────────────────────────────────────────────────────────────────────
    # BLUETOOTH
    # ─────────────────────────────────────────────────────────────────────────
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    services.blueman.enable = true;
    
    # ─────────────────────────────────────────────────────────────────────────
    # GRAPHICS
    # ─────────────────────────────────────────────────────────────────────────
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
    
    # ─────────────────────────────────────────────────────────────────────────
    # FONTS
    # ─────────────────────────────────────────────────────────────────────────
    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-color-emoji
    ];
    
    # ─────────────────────────────────────────────────────────────────────────
    # DESKTOP PACKAGES
    # ─────────────────────────────────────────────────────────────────────────
    environment.systemPackages = with pkgs; [
      pavucontrol
      pamixer
      bibata-cursors
      wl-clipboard
    ];
    
    # ─────────────────────────────────────────────────────────────────────────
    # HOME MANAGER
    # ─────────────────────────────────────────────────────────────────────────
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      
      users.${meta.owner.username} = { pkgs, ... }: {
        programs.home-manager.enable = true;
        
        home = {
          username = meta.owner.username;
          homeDirectory = "/home/${meta.owner.username}";
          stateVersion = meta.defaults.stateVersion;
        };
        
        # Cursor theme
        home.pointerCursor = {
          name = meta.defaults.cursor.name;
          size = meta.defaults.cursor.size;
          package = pkgs.bibata-cursors;
          gtk.enable = true;
          x11.enable = true;
        };
        
        # Git configuration
        programs.git = {
          enable = true;
          settings = {
            user.name = meta.owner.name;
            user.email = meta.owner.email;
            init.defaultBranch = meta.defaults.git.defaultBranch;
            core.editor = meta.defaults.editor;
          };
        };
        
        # Fish shell
        programs.fish = {
          enable = meta.defaults.shell == "fish";
          shellAliases = {
            rebuild = "sudo nixos-rebuild switch --flake ~/.dotfiles";
            update = "nix flake update ~/.dotfiles && sudo nixos-rebuild switch --flake ~/.dotfiles";
            clean = "sudo nix-collect-garbage -d";
            ll = "ls -la";
            ".." = "cd ..";
            g = "git";
            gs = "git status -sb";
            ga = "git add";
            gc = "git commit";
            gp = "git push";
            gl = "git pull";
          };
        };
        
        # Starship prompt
        programs.starship = {
          enable = true;
          settings = {
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
          };
        };
        
        # Lazygit
        programs.lazygit.enable = true;
        
        # Btop
        programs.btop.enable = true;

        # KDE Connect
        programs.kdeconnect = {
          enable = true;
          indicator = true;
        };
      };
    };
    
    # ─────────────────────────────────────────────────────────────────────────
    # SERVICES
    # ─────────────────────────────────────────────────────────────────────────
    services = {
      # Power management
      upower.enable = true;
      power-profiles-daemon.enable = lib.mkDefault true;
      
      # Firmware updates
      fwupd.enable = true;
    };
    
    # dconf for GNOME apps
    programs.dconf.enable = true;
  };
}


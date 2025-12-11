{ pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  modules = {
    # Use sin's profile (sets user, git, shell customizations)
    profiles.sin.enable = true;
    
    # Core
    network.hostName = "obelisk";
    locale = {
      timeZone = "America/New_York";
      locale = "en_US.UTF-8";
    };

    # Hardware
    nvidia.enable = true;
    audio.enable = true;
    bluetooth.enable = true;
    secureboot.enable = true;

    monitors.displays = [
      {
        name = "HDMI-A-1";
        width = 3840;
        height = 2160;
        refreshRate = 240;
        scale = 1.5;
        hdr = true;
        vrr = true;
      }
    ];

    # Interface
    hyprland = {
      enable = true;
      autoLogin = true;
      terminal = "kitty";
      fileManager = "nautilus";
      cursor = {
        name = "Bibata-Modern-Classic";
        size = 24;
      };
      
      caelestia = {
        enable = true;
        wallpaperDir = "~/Pictures/Wallpapers";
        showBattery = false;
      };
    };

    # Applications
    gaming.enable = true;
    zen-browser.enable = true;

    development = {
      enable = true;
      languages = {
        nix = true;
        c = true;
      };
      editors = {
        neovim = true;
        vscode = true;
      };
    };
  };
  
  services.openssh.enable = true;
}

{ pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  modules = {
    # Use sin's profile (sets user, git, shell customizations)
    profiles.sin = {
      enable = true;
      type = "desktop";
    };
    
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
    
    hibernation = {
      enable = true;
      resumeDevice = "5463af7b-e287-4f0c-8a3a-d87398592c2b";
      swapfileOffset = 968969;
    };

    monitors.displays = [
      {
        name = "HDMI-A-1";
        width = 3840;
        height = 2160;
        refreshRate = 240;
        scale = 1.5;
        hdr = true;
        vrr = 3;  # 0=off, 1=on, 2=fullscreen, 3=fullscreen+game
      }
    ];

    # Interface - Using Noctalia shell with Hyprland
    noctalia = {
      enable = true;
      windowManager = "hyprland";  # or "niri" to switch compositors
      
      # Shared settings (passed to selected WM)
      autoLogin = true;
      terminal = "kitty";
      fileManager = "nautilus";
      cursor = {
        name = "Bibata-Modern-Classic";
        size = 24;
      };
      
      # Noctalia-specific settings
      wallpaperDir = "~/Pictures/Wallpapers";
      showBattery = false;
      bar = {
        position = "top";
        density = "default";
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

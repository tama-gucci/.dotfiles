{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.gaming;
in
{
  options.modules.gaming = {
    enable = mkEnableOption "Gaming support (Steam, Proton, Wine)";
  };
  config = mkIf cfg.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;      # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    };    
    environment.systemPackages = with pkgs; [ 
      gamemode        # CLI for GameMode
      mangohud       
      steam-run       # Run non-Steam games with Steam runtime
      protonup-qt     # GUI to manage Proton-GE versions
      wineWowPackages.stable   
      winetricks              
      protontricks             
      umu-launcher
      faugus-launcher
    ];             
  };
}

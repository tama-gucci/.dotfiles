{ pkgs, ... }:

{
  # NixOS state version - DO NOT CHANGE after initial install
  system.stateVersion = "25.11";
  
  # Minimal essential system packages
  # User packages should go in modules.user.packages or specific modules
  environment.systemPackages = with pkgs; [
    curl
    wget
    vim       # Fallback editor
  ];
}

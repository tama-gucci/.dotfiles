{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.modules.zen-browser;
in
{
  options.modules.zen-browser = {
    enable = mkEnableOption "Zen Browser";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      inputs.zen-browser.packages.${pkgs.system}.default
    ];
  };
}

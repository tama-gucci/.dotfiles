{ config, lib, ... }:

with lib;

{
  options.modules.network = {
    hostName = mkOption {
      type = types.str;
      default = "nixos";
      description = "Machine hostname (appears in terminal prompt, network)";
    };
  };

  config = {
    networking = {
      hostName = config.modules.network.hostName;
      networkmanager.enable = true;
      firewall.enable = true;
    };
  };
}

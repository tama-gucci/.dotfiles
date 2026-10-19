{ config, inputs, ... }:
let
  username = config.flake.meta.owner.username;
in
{
  flake.modules.nixos.chrysalis = { config, ... }: {
    imports = [ inputs.chrysalis.nixosModules.default ];
    programs.chrysalis-pi = {
      enable = true;
      user = username;
      host = config.networking.hostName;
      configurationDirectory = "/home/${username}/.dotfiles";
      stateDirectory = "/var/lib/chrysalis/state";
    };
  };
}

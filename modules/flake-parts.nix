# ═══════════════════════════════════════════════════════════════════════════
# FLAKE-PARTS MODULES SETUP
# ═══════════════════════════════════════════════════════════════════════════
# This module enables the flake.modules option from flake-parts
# which allows us to define named NixOS/home-manager modules
# that can be composed in configurations
{ inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];
}

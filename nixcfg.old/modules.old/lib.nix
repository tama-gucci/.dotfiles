# Shared library of helper functions for NixOS configuration
{ lib, ... }:

with lib;

{
  # Helper to create a simple enable option with description
  mkEnableOpt = description: mkEnableOption description;
  
  # Helper to create a string option with default
  mkStrOpt = default: description: mkOption {
    type = types.str;
    inherit default description;
  };
  
  # Helper to create an int option with default
  mkIntOpt = default: description: mkOption {
    type = types.int;
    inherit default description;
  };
  
  # Helper to create a bool option with default
  mkBoolOpt = default: description: mkOption {
    type = types.bool;
    inherit default description;
  };
  
  # Helper to create a package list option
  mkPkgsOpt = description: mkOption {
    type = types.listOf types.package;
    default = [];
    inherit description;
  };
}

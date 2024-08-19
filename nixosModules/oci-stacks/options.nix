{ lib, ... }:
with lib;
let
  stackOptions = args: {
    options = {
      services = mkOption {
        default = builtins.trace args { };
        type = types.attrsOf (types.submodule serviceOptions);
        description = ""; # TODO
      };

      networks = mkOption {
        default = { };
        type = types.attrsOf (types.submodule networkOptions);
        description = "Attribute set of network definitions."; # TODO
      };
    };
  };

  serviceOptions = args: { options = { }; };

  networkOptions = args: {
    options = {
      labels = mkOption {
        default = { };
        type = types.attrsOf types.str;
      };
    };
  };
in
{
  options = {
    virtualisation.oci-stacks = {
      stacks = mkOption {
        default = { };
        type = types.attrsOf (types.submodule stackOptions);
        description = "Stacks of OCI containers to run";
      };
    };
  };
}

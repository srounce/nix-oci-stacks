{ lib, options, ... }:
with lib;
let
  stackOptions = args: {
    options = {
      services = mkOption {
        default = { };
        type = types.attrsOf (types.submodule containerOptions);
        description = ""; # TODO
      };

      networks = mkOption {
        default = { };
        type = types.attrsOf (types.submodule networkOptions);
        description = "Attribute set of network definitions."; # TODO
      };
    };
  };

  containerOptions = args: {
    options = (
      builtins.removeAttrs (options.virtualisation.oci-containers.containers.type.getSubOptions [ ]) [
        "_module"
      ]
    );
  };

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

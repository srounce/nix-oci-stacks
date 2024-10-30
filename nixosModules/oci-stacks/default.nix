{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.virtualisation.oci-stacks;

  #mkStack = stackArgs@{ backend }: backends.${backend}.mkStack stackArgs;

  backends.podman = rec {
    mkStackNetworks =
      { name, networks, ... }:
      let
        defaultNetwork = mkNetwork {
          name = "${name}_default";
          stackName = name;
          labels = {
            oci-stacks-type = "default";
          };
        };
      in
      {
        "${defaultNetwork.name}" = defaultNetwork.value;
      }
      // (lib.mapAttrs' (
        networkName: networkCfg:
        mkNetwork (
          networkCfg
          // {
            name = "${name}_${networkName}";
            stackName = name;
          }
        )
      ) networks);

    mkNetwork =
      {
        name,
        stackName,
        labels,
      }:
      let
        countAttrs = attrs: builtins.length (lib.attrNames attrs);

        hasAttrs = attrs: countAttrs attrs > 0;

        attrsToLabels = attrs: lib.mapAttrsToList (name: value: "${name}=${value}") attrs;

        networkCreateArgs =
          [ ]
          ++ (lib.optional (hasAttrs labels) "--label ${lib.concatStringsSep "," (attrsToLabels labels)}");
      in
      {
        name = "oci-stacks-network-podman-${name}";
        value = {
          path = [ pkgs.podman ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStop = "podman network rm -f ${name}";
          };
          script = ''
            podman network exists ${name} || \
            podman network create ${name} ${lib.concatStrings networkCreateArgs}

          '';
          partOf = [ "oci-stacks-${stackName}-root.target" ];
          wantedBy = [ "oci-stacks-${stackName}-root.target" ];
        };
      };

    mkContainer =
      args:
      let
        containerArgs = builtins.removeAttrs args [
          "stackName"
          "dependsOn"
          "networks"
        ];
      in
      containerArgs
      // {
        dependsOn = builtins.map (depName: "${args.stackName}-${depName}") args.dependsOn;
        extraOptions = lib.concatMap (network: [ "--network" "${args.stackName}_${network}" ]) args.networks;
      };
  };

  activeBackend = config.virtualisation.oci-containers.backend;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.stacks != { }) (
    lib.mkMerge [
      # Per-stack root targets
      {
        systemd.targets = lib.mapAttrs' (name: _: {
          name = "oci-stacks-${name}-root";
          value = {
            wantedBy = [ "multi-user.target" ];
          };
        }) cfg.stacks;
      }
      # Networks
      {
        systemd.services = lib.concatMapAttrs (
          name: stackCfg: backends.${activeBackend}.mkStackNetworks (stackCfg // { inherit name; })
        ) cfg.stacks;
      }
      # Containers 
      {
        virtualisation.oci-containers.containers = lib.concatMapAttrs (
          stackName: stack:
          (lib.mapAttrs' (svcName: container: {
            name = "${stackName}_${svcName}";
            value = backends.${activeBackend}.mkContainer (container // { stackName = stackName; });
          }) stack.services or { })
        ) cfg.stacks;
      }
    ]
  );
}

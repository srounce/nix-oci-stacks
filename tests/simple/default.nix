{ pkgs, nixosModules, ... }:
let
  testHelper = {
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
        PermitEmptyPasswords = "yes";
      };
    };

    environment.systemPackages = [
      pkgs.sysz
      pkgs.curl
    ];

    security.pam.services.sshd.allowNullPassword = true;

    virtualisation.forwardPorts = [
      {
        from = "host";
        host.port = 2000;
        guest.port = 22;
      }
    ];
  };
in
pkgs.nixosTest {
  name = "oci-stacks-simple";

  nodes = {
    machine =
      { ... }:
      {
        imports = [
          nixosModules.oci-stacks
          testHelper
        ];

        networking.firewall.enable = false;

        virtualisation.oci-containers.backend = "podman";

        virtualisation.oci-stacks.stacks.test-stack = {
          services = {
            web = {
              image = "nginx";
              imageStream = pkgs.dockerTools.examples.nginxStream;
              ports = [ "8080:80" ];
            };
          };
          networks = {
            webstack = {
              labels = {
                group = "web";
              };
            };
          };
        };
      };
  };

  testScript = builtins.readFile ./testScript.py;
}

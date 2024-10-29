start_all()
serial_stdout_off()

# machine.shell_interact()

machine.wait_for_unit("oci-stacks-test-stack-root.target")

machine.succeed("podman network exists test-stack_default")
machine.succeed("podman network exists test-stack_webstack")

machine.wait_for_unit("podman-test-stack_web.service")
machine.wait_for_open_port(8080)
machine.wait_until_succeeds("podman container inspect test-stack_web")
machine.succeed("curl localhost:8080")

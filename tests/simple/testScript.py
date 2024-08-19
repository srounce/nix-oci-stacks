start_all()
serial_stdout_off()

machine.shell_interact()

machine.wait_for_unit("oci-stacks-network-podman-test-stack_default.service")
machine.wait_for_unit("oci-stacks-network-podman-test-stack_webstack.service")

machine.succeed("podman network exists test-stack_default")
machine.succeed("podman network exists test-stack_webstack")

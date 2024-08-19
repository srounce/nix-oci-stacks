start_all()
serial_stdout_off()

machine.shell_interact()

machine.wait_for_unit("oci-stacks-test-stack-root.target")


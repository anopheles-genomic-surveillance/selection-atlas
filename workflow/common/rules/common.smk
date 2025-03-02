# Common rules for both workflows.
#
# Assume a `setup` variable has been assigned as an instance of `AtlasSetup`.


rule set_kernel:
    # This rule is a hack to ensure that the "selection-atlas" conda
    # environment has been configured as a Jupyter kernel, so it is
    # accessible by name via papermill.
    input:
        setup.environment_file,
    output:
        touch(setup.kernel_set_file),
    conda:
        setup.environment_file
    log:
        "logs/set_kernel.log",
    shell:
        """
        python -m ipykernel install --user --name selection-atlas 2> {log}
        """

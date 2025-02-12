# Common rules for both workflows.


rule set_kernel:
    # This rule is a hack to ensure that the "selection-atlas" conda
    # environment has been configured as a Jupyter kernel, so it is
    # accessible by name via papermill.
    input:
        environment_file,
    output:
        touch(kernel_set_file),
    conda:
        environment_file
    log:
        "logs/set_kernel.log",
    shell:
        """
        python -m ipykernel install --user --name selection-atlas 2> {log}
        """

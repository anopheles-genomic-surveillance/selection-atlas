rule set_kernel:
    input:
        f'{workflow.basedir}/environment.yml'
    output:
        touch("resources/.kernel.set")
    conda: f'{workflow.basedir}/environment.yml'
    log:
        "logs/set_kernel.log"
    shell: 
        """
        python -m ipykernel install --user --name selection-atlas 2> log
        """

def get_final_cohorts():
    return checkpoint.final_cohorts.get()
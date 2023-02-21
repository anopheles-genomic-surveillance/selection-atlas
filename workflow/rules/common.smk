rule set_kernel:
    input:
        f'{workflow.basedir}/../environment.yml'
    output:
        touch("build/.kernel.set")
    conda: f'{workflow.basedir}/../environment.yml'
    log:
        "logs/set_kernel.log"
    shell: 
        """
        python -m ipykernel install --user --name selection-atlas 2> log
        """


def get_h12_calibration_yamls(wildcards):
    df = pd.read_csv(checkpoints.setup_cohorts.get().output[1])
    paths = "build/h12-calibration/" + df['cohort_id'] + ".yaml"
    return (paths)

def get_h12_calibration_cohorts(wildcards):
    df = pd.read_csv(checkpoints.setup_cohorts.get().output[1])
    paths = "build/notebooks/h12-calibration-" + df['cohort_id'] + ".ipynb"
    return (paths)

def get_h12_final_cohorts(wildcards):
    df = pd.read_csv(checkpoints.final_cohorts.get().output[1])
    paths = "build/notebooks/h12-gwss-" + df['cohort_id'] + ".ipynb"
    return (paths)

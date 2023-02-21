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

def get_final_cohorts():
    _ = checkpoint.final_cohorts.get()
    df = pd.read_csv("build/final_cohorts.csv")
    print(df)
    return df['cohorts_id'].to_list()
import pandas as pd
import geopandas as gpd
import yaml
import os


# Open configuration file and set up utility variables.
configfile: "config/main.yaml"


# Define global variables.
configpath = workflow.configfiles[0]
chromosomes = config["contigs"]
analysis_version = config["analysis_version"]
analysis_dir = f"results/{analysis_version}/analysis"
site_dir = f"results/{analysis_version}/site"


include: "rules/site.smk"


rule all:
    input:
        # This is the output from the Jupyter book compilation.
        f"{site_dir}/docs/_build",


rule set_kernel:
    # Rule to force setting a kernel, required for papermill.
    input:
        f"{workflow.basedir}/../environment.yml",
    output:
        touch("results/kernel.set"),
    log:
        "logs/set_kernel.log",
    shell:
        """
        python -m ipykernel install --user --name selection-atlas 2> {log}
        """

import pandas as pd
import geopandas as gpd
import yaml
import os


# Open configuration file and set up utility variables.
configfile: "workflow/config.yaml"


# Define global variables.
configpath = workflow.configfiles[0]
chromosomes = config["contigs"]
analysis_version = config["analysis_version"]
analysis_dir = f"build/{analysis_version}/analysis"
site_dir = f"build/{analysis_version}/site"


include: "rules/site.smk"


rule all:
    input:
        # This is the output from the Jupyter book build.
        build=f"{site_dir}/docs/_build",


rule set_kernel:
    # Rule to force setting a kernel, required for papermill.
    input:
        f"{workflow.basedir}/../environment.yml",
    output:
        touch(".kernel.set"),
    log:
        "logs/set_kernel.log",
    shell:
        """
        python -m ipykernel install --user --name selection-atlas 2> {log}
        """

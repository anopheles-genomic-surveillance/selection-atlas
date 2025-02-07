import pandas as pd
import geopandas as gpd
import yaml
import os

# open configuration file
configfile: "workflow/config.yaml"
configpath = workflow.configfiles[0]
chromosomes = config["contigs"]
analysis_version = config["analysis_version"]
build_dir = f"build/{analysis_version}"


def get_selection_atlas_site_pages(wildcards):
    """Construct a list of all files required to build the Jupyter book site."""
    
    # Read in cohorts dataframe.
    df = gpd.read_file(f"{build_dir}/final_cohorts.geojson")
    
    # Build a list of all required files.
    wanted_outputs = expand(
        [
            "docs/home-page.ipynb",
            "docs/country/{country}.ipynb",
            "docs/genome/ag-{chrom}.ipynb",
            "docs/cohort/{cohort}.ipynb",
            "docs/alert/SA-AG-{alert}.ipynb",
        ],    
        country=df['country_alpha2'],
        chrom=chromosomes,
        cohort=df['cohort_id'].unique(),
        alert=config['alerts'],
    )
    
    return wanted_outputs 


def get_h12_signal_detection_csvs(wildcards):

    # Read in cohorts.
    df = pd.read_csv(f"{build_dir}/final_cohorts.csv")
    
    # Build a list of file paths.
    paths = expand(
        "{build_dir}/h12-signal-detection/{cohort}_{contig}.csv", 
        cohort=df['cohort_id'], 
        contig=chromosomes, 
        build_dir=build_dir,
    )
    return paths
  

include: "rules/site.smk"


rule all:
    input:
        build = "docs/_build"


rule set_kernel:
    input:
        f"{workflow.basedir}/../environment.yml"
    output:
        touch(".kernel.set")
    log:
        "logs/set_kernel.log"
    shell: 
        """
        python -m ipykernel install --user --name selection-atlas 2> {log}
        """

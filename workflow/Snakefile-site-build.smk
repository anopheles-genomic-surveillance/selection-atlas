import pandas as pd
import geopandas as gpd
import yaml

# open configuration file
configfile: "workflow/config.yaml"
configpath = workflow.configfiles[0]
chromosomes = config["contigs"]
analysis_version = config["analysis_version"]
build_dir = f"build/{analysis_version}"

# we dont use checkpoints in the site workflow, so need separate functions to the other workflow
def get_selection_atlas_site_pages(wildcards):
    df = gpd.read_file(f"{build_dir}/final_cohorts.geojson")

    wanted_outputs = []
    wanted_outputs.extend(
                expand([
                    "docs/home-page.ipynb",
                    "docs/country/{country}.ipynb",
                    "docs/genome/ag-{chrom}.ipynb",
                    "docs/cohort/{cohort}.ipynb",
                    ],    
                 country=df['country_alpha2'],
                 chrom=chromosomes,
                 cohort=df['cohort_id'].unique()
              )
    )
    print("wanted_outputs", wanted_outputs)
    return wanted_outputs 

def get_h12_signal_detection_csvs(wildcards):

    df = pd.read_csv(f"{build_dir}/final_cohorts.csv")
    paths = expand("{build_dir}/h12-signal-detection/{cohort}_{contig}.csv", cohort=df['cohort_id'], contig=chromosomes, build_dir=build_dir)
    
    return paths
    
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

# include rule files
include: "rules/site.smk"
include: "rules/utility.smk"


rule all:
    input:
        site = get_selection_atlas_site_pages,
        build = "docs/_build/"

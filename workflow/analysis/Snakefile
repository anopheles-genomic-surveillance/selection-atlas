import pandas as pd
import geopandas as gpd
import yaml


# open configuration file
configfile: "config/main.yaml"


configpath = workflow.configfiles[0]
chromosomes = config["contigs"]
analysis_version = config["analysis_version"]
analysis_dir = f"results/{analysis_version}/analysis"


# include rule files
include: "rules/common.smk"
include: "rules/cohorts.smk"
include: "rules/gwss.smk"


rule all:
    input:
        analyses=get_selection_atlas_outputs,

import pandas as pd
import geopandas as gpd
import yaml

# open configuration file
configfile: "workflow/config.yaml"
configpath = workflow.configfiles[0]
chromosomes = config["contigs"]
analysis_version = config["analysis_version"]
build_dir = f"build/{analysis_version}"

# include rule files
include: "rules/common.smk"
include: "rules/cohorts.smk"
include: "rules/gwss.smk"
include: "rules/utility.smk"

rule all:
    input:
        analyses = get_selection_atlas_outputs
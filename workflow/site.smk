import pandas as pd
import geopandas as gpd
import yaml
import os


# Open configuration file and set up utility variables.
configfile: "workflow/config.yaml"


configpath = workflow.configfiles[0]
chromosomes = config["contigs"]
analysis_version = config["analysis_version"]
analysis_dir = f"build/{analysis_version}/analysis"
site_dir = f"build/{analysis_version}/site"


def get_selection_atlas_site_files(wildcards):
    """Construct a list of all files required to build the Jupyter book site."""

    # Read in cohorts dataframe.
    df = gpd.read_file(f"{analysis_dir}/final_cohorts.geojson")

    # Build a list of all required files.
    site_files = expand(
        [
            f"{site_dir}/docs/_config.yml",
            f"{site_dir}/docs/_toc.yml",
            f"{site_dir}/docs/home-page.ipynb",
            f"{site_dir}/docs/alerts.ipynb",
            f"{site_dir}/docs/country/{{country}}.ipynb",
            f"{site_dir}/docs/genome/ag-{{chrom}}.ipynb",
            f"{site_dir}/docs/cohort/{{cohort}}.ipynb",
            f"{site_dir}/docs/alert/SA-AG-{{alert}}.ipynb",
        ],
        country=df["country_alpha2"],
        chrom=chromosomes,
        cohort=df["cohort_id"].unique(),
        alert=config["alerts"],
    )

    return site_files


def get_h12_signal_detection_csvs(wildcards):

    # Read in cohorts.
    df = pd.read_csv(f"{analysis_dir}/final_cohorts.csv")

    # Build a list of file paths.
    paths = expand(
        "{analysis_dir}/h12-signal-detection/{cohort}_{contig}.csv",
        cohort=df["cohort_id"],
        contig=chromosomes,
        analysis_dir=analysis_dir,
    )
    return paths


include: "rules/site.smk"


rule all:
    input:
        build=f"{site_dir}/docs/_build",


rule set_kernel:
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

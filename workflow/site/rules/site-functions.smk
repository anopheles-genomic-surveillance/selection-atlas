# Functions for the GWSS workflow.
#
# Assume a `setup` variable has been assigned as an instance of `AtlasSetup`.


import pandas as pd
import geopandas as gpd


def get_selection_atlas_site_files(wildcards):
    """Construct a list of all files required to compile the Jupyter book site."""

    # Read in cohorts dataframe.
    df = gpd.read_file(setup.final_cohorts_geojson_file)
    cohorts = df["cohort_id"]  # .unique()
    countries = df["country_alpha2"]
    alerts = config["alerts"]
    contigs = config["contigs"]

    # Dynamically-generated files.
    site_files = expand(
        [
            f"{setup.jb_source_dir}/_toc.yml",
            f"{setup.jb_source_dir}/_config.yml",
            f"{setup.jb_source_dir}/index.ipynb",
            f"{setup.jb_source_dir}/country/{{country}}.ipynb",
            f"{setup.jb_source_dir}/contig/{{contig}}.ipynb",
            f"{setup.jb_source_dir}/cohort/{{cohort}}.ipynb",
            f"{setup.jb_source_dir}/alert/{{alert}}.ipynb",
        ],
        country=countries,
        contig=contigs,
        cohort=cohorts,
        alert=alerts,
    )

    # Static files.
    site_files += [f"{setup.jb_source_dir}/{p}" for p in setup.static_site_files]

    return site_files


def get_h12_signal_files(wildcards):

    # Read in cohorts.
    df = pd.read_csv(setup.final_cohorts_file)
    cohorts = df["cohort_id"]

    # Create a list of file paths.
    paths = expand(
        setup.h12_signal_files,
        cohort=cohorts,
        contig=config["contigs"],
    )
    return paths

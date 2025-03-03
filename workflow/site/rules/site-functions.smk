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

    # Create a list of all required files.
    site_files = expand(
        [
            f"{setup.site_results_dir}/docs/_config.yml",
            f"{setup.site_results_dir}/docs/_toc.yml",
            f"{setup.site_results_dir}/docs/index.ipynb",
            f"{setup.site_results_dir}/docs/alerts.ipynb",
            f"{setup.site_results_dir}/docs/country/{{country}}.ipynb",
            f"{setup.site_results_dir}/docs/contig/{{contig}}.ipynb",
            f"{setup.site_results_dir}/docs/cohort/{{cohort}}.ipynb",
            f"{setup.site_results_dir}/docs/alert/{{alert}}.ipynb",
            f"{setup.site_results_dir}/docs/methods.md",
            f"{setup.site_results_dir}/docs/faq.md",
            f"{setup.site_results_dir}/docs/glossary.md",
            f"{setup.site_results_dir}/docs/logo.png",
            f"{setup.site_results_dir}/docs/favicon.ico",
            f"{setup.site_results_dir}/docs/_static/custom.css",
        ],
        country=countries,
        contig=contigs,
        cohort=cohorts,
        alert=alerts,
    )

    return site_files


def get_h12_signal_files(wildcards):

    # Read in cohorts.
    df = pd.read_csv(setup.final_cohorts_file)
    cohorts = df["cohort_id"]

    # Create a list of file paths.
    paths = expand(
        h12_signal_files,
        cohort=cohorts,
        contig=contigs,
    )
    return paths

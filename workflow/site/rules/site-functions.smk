# Expects that variables and functions defined in workflow/common/scripts/setup.py
# are available.


import pandas as pd
import geopandas as gpd


def get_selection_atlas_site_files(wildcards):
    """Construct a list of all files required to compile the Jupyter book site."""

    # Read in cohorts dataframe.
    df = gpd.read_file(final_cohorts_geojson_file)
    cohorts = df["cohort_id"]  # .unique()
    countries = df["country_alpha2"]
    alerts = config["alerts"]

    # Create a list of all required files.
    site_files = expand(
        [
            f"{site_results_dir}/docs/_config.yml",
            f"{site_results_dir}/docs/_toc.yml",
            f"{site_results_dir}/docs/home-page.ipynb",
            f"{site_results_dir}/docs/alerts.ipynb",
            f"{site_results_dir}/docs/country/{{country}}.ipynb",
            f"{site_results_dir}/docs/contig/ag-{{contig}}.ipynb",
            f"{site_results_dir}/docs/cohort/{{cohort}}.ipynb",
            f"{site_results_dir}/docs/alert/SA-AG-{{alert}}.ipynb",
        ],
        country=countries,
        contig=contigs,
        cohort=cohorts,
        alert=alerts,
    )

    return site_files


def get_h12_signal_files(wildcards):

    # Read in cohorts.
    df = pd.read_csv(final_cohorts_file)
    cohorts = df["cohort_id"]

    # Create a list of file paths.
    paths = expand(
        h12_signal_files,
        cohort=cohorts,
        contig=contigs,
    )
    return paths

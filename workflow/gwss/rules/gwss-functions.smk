# Functions for the GWSS workflow.
#
# Assume a `setup` variable has been assigned as an instance of `AtlasSetup`.


import pandas as pd


def get_h12_calibration_files(wildcards):
    df = pd.read_csv(checkpoints.setup_cohorts.get().output.cohorts)
    cohorts = df["cohort_id"]
    paths = expand(
        setup.h12_calibration_files,
        cohort=cohorts,
    )
    return paths


def get_h12_signal_files(wildcards):
    df = pd.read_csv(checkpoints.finalize_cohorts.get().output.final_cohorts)
    cohorts = df["cohort_id"]
    paths = expand(
        setup.h12_signal_files,
        contig=setup.contigs,
        cohort=cohorts,
    )
    return paths


def get_gwss_results(wildcards):
    """Collect all expected result files from the GWSS."""

    # df = gpd.read_file(checkpoints.geolocate_cohorts.get().output.final_cohorts_geojson)
    df = pd.read_csv(checkpoints.finalize_cohorts.get().output.final_cohorts)
    cohorts = df["cohort_id"]

    # Define paths to output files.
    h12_cal_paths = expand(
        setup.h12_calibration_files,
        cohort=cohorts,
    )
    h12_cal_nb_paths = expand(
        f"{setup.gwss_results_dir}/notebooks/h12-calibration-{{cohort}}.ipynb",
        cohort=cohorts,
    )
    h12_gwss_nb_paths = expand(
        f"{setup.gwss_results_dir}/notebooks/h12-gwss-{{cohort}}.ipynb",
        cohort=cohorts,
    )
    h12_signal_paths = expand(
        setup.h12_signal_files,
        contig=setup.contigs,
        cohort=cohorts,
    )
    g123_cal_paths = expand(
        setup.g123_calibration_files,
        cohort=cohorts,
    )
    g123_cal_nb_paths = expand(
        f"{setup.gwss_results_dir}/notebooks/g123-calibration-{{cohort}}.ipynb",
        cohort=cohorts,
    )
    g123_gwss_nb_paths = expand(
        f"{gwss_results_dir}/notebooks/g123-gwss-{{cohort}}.ipynb",
        cohort=cohorts,
    )
    ihs_gwss_nb_paths = expand(
        f"{setup.gwss_results_dir}/notebooks/ihs-gwss-{{cohort}}.ipynb",
        cohort=cohorts,
    )

    # Add all output files to a list.
    results = [setup.final_cohorts_geojson_file]
    results.extend(h12_cal_paths)
    results.extend(h12_cal_nb_paths)
    results.extend(h12_gwss_nb_paths)
    results.extend(h12_signal_paths)
    results.extend(g123_cal_paths)
    results.extend(g123_cal_nb_paths)
    results.extend(g123_gwss_nb_paths)
    results.extend(ihs_gwss_nb_paths)

    return results

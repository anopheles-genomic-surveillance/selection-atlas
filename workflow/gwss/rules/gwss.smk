# Expects that variables and functions defined in workflow/scripts/setup.py
# are available.

import pandas as pd

# import geopandas as gpd


def get_h12_calibration_files(wildcards):
    df = pd.read_csv(checkpoints.setup_cohorts.get().output.cohorts)
    cohorts = df["cohort_id"]
    paths = expand(
        h12_calibration_files,
        cohort=cohorts,
    )
    return paths


def get_h12_signal_files(wildcards):
    df = pd.read_csv(checkpoints.final_cohorts.get().output.final_cohorts)
    cohorts = df["cohort_id"]
    paths = expand(
        h12_signal_files,
        cohort=cohorts,
        contig=contigs,
    )
    return paths


def get_gwss_results(wildcards):
    """Collect all expected result files from the GWSS."""

    # df = gpd.read_file(checkpoints.geolocate_cohorts.get().output.final_cohorts_geojson)
    df = pd.read_csv(checkpoints.final_cohorts.get().output.final_cohorts)
    cohorts = df["cohort_id"]

    # Define paths to output files.
    h12_cal_paths = expand(
        h12_calibration_files,
        cohort=cohorts,
    )
    h12_cal_nb_paths = expand(
        f"{gwss_results_dir}/notebooks/h12-calibration-{{cohort}}.ipynb",
        cohort=cohorts,
    )
    h12_gwss_nb_paths = expand(
        f"{gwss_results_dir}/notebooks/h12-gwss-{{cohort}}.ipynb",
        cohort=cohorts,
    )
    h12_signal_paths = expand(
        h12_signal_files,
        cohort=cohorts,
        contig=contigs,
    )
    g123_cal_paths = expand(
        g123_calibration_files,
        cohort=cohorts,
    )
    g123_cal_nb_paths = expand(
        f"{gwss_results_dir}/notebooks/g123-calibration-{{cohort}}.ipynb",
        cohort=cohorts,
    )
    g123_gwss_nb_paths = expand(
        f"{gwss_results_dir}/notebooks/g123-gwss-{{cohort}}.ipynb",
        cohort=cohorts,
    )
    ihs_gwss_nb_paths = expand(
        f"{gwss_results_dir}/notebooks/ihs-gwss-{{cohort}}.ipynb",
        cohort=cohorts,
    )

    # Add all output files to a list.
    results = []
    results.extend(h12_cal_paths)
    results.extend(h12_cal_nb_paths)
    results.extend(h12_gwss_nb_paths)
    results.extend(h12_signal_paths)
    results.extend(g123_cal_paths)
    results.extend(g123_cal_nb_paths)
    results.extend(g123_gwss_nb_paths)
    results.extend(ihs_gwss_nb_paths)

    return results


checkpoint setup_cohorts:
    """
    Setup cohorts for analysis using the config file.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/setup-cohorts.ipynb",
        config=workflow_config_file,
        kernel=kernel_set_file,
    output:
        nb=f"{gwss_results_dir}/notebooks/setup-cohorts.ipynb",
        cohorts=cohorts_file,
    log:
        "logs/setup_cohorts.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -f {input.config} 2> {log}
        """


rule h12_calibration:
    """Calibrate the window size for each cohort."""
    input:
        nb=f"{workflow.basedir}/notebooks/h12-calibration.ipynb",
        config=workflow_config_file,
        kernel=kernel_set_file,
    output:
        nb=f"{gwss_results_dir}/notebooks/h12-calibration-{{cohort}}.ipynb",
        calibration=h12_calibration_files,
    log:
        "logs/h12_calibration/{cohort}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas \
        -p cohort_id {wildcards.cohort} -f {input.config} 2> {log}
        """


checkpoint final_cohorts:
    """
    Finalize cohorts for analysis based on the calibration results.
    """
    input:
        calibration=get_h12_calibration_files,
        nb=f"{workflow.basedir}/notebooks/final-cohorts.ipynb",
        config=workflow_config_file,
        cohorts=lambda wildcards: checkpoints.setup_cohorts.get().output.cohorts,
        kernel=kernel_set_file,
    output:
        nb=f"{gwss_results_dir}/notebooks/final-cohorts.ipynb",
        final_cohorts=final_cohorts_file,
    log:
        "logs/final_cohorts.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -f {input.config} 2> {log}
        """


checkpoint geolocate_cohorts:
    input:
        nb=f"{workflow.basedir}/notebooks/geolocate-cohorts.ipynb",
        config=workflow_config_file,
        final_cohorts=lambda wildcards: checkpoints.final_cohorts.get().output.final_cohorts,
        kernel=kernel_set_file,
    output:
        nb=f"{gwss_results_dir}/notebooks/geolocate-cohorts.ipynb",
        final_cohorts_geojson=final_cohorts_geojson_file,
    log:
        "logs/geolocate_cohorts.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -f {input.config} 2> {log}
        """


rule h12_gwss:
    """Run the H12 GWSS."""
    input:
        nb=f"{workflow.basedir}/notebooks/h12-gwss.ipynb",
        calibration=h12_calibration_files,
        cohorts=final_cohorts_file,
        config=workflow_config_file,
        kernel=kernel_set_file,
    output:
        nb=f"{gwss_results_dir}/notebooks/h12-gwss-{{cohort}}.ipynb",
    log:
        "logs/h12_gwss/{cohort}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p cohort_id {wildcards.cohort} \
        -f {input.config} 2> {log}
        """


rule h12_signal_detection:
    """Detect peaks/signals from the H12 GWSS data."""
    input:
        nb=f"{workflow.basedir}/notebooks/h12-signal-detection.ipynb",
        gwss_nb=f"{gwss_results_dir}/notebooks/h12-gwss-{{cohort}}.ipynb",
        utils_nb=f"{workflow.basedir}/notebooks/peak-utils.ipynb",
        cohorts=final_cohorts_file,
        config=workflow_config_file,
        kernel=kernel_set_file,
    output:
        nb=f"{gwss_results_dir}/notebooks/h12-signal-detection-{{cohort}}-{{contig}}.ipynb",
        signals=h12_signal_files,
    log:
        "logs/h12_signal_detection/{cohort}_{contig}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p cohort_id {wildcards.cohort} \
         -p contig {wildcards.contig} -f {input.config} 2> {log}
        """


rule g123_calibration:
    """Calibrate the window size for each cohort."""
    input:
        nb=f"{workflow.basedir}/notebooks/g123-calibration.ipynb",
        config=workflow_config_file,
        kernel=kernel_set_file,
    output:
        nb=f"{gwss_results_dir}/notebooks/g123-calibration-{{cohort}}.ipynb",
        calibration=g123_calibration_files,
    log:
        "logs/g123_calibration/{cohort}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas \
        -p cohort_id {wildcards.cohort} -f {input.config} 2> {log}
        """


rule g123_gwss:
    """Run the G123 GWSS."""
    input:
        nb=f"{workflow.basedir}/notebooks/g123-gwss.ipynb",
        calibration=g123_calibration_files,
        cohorts=final_cohorts_file,
        config=workflow_config_file,
        kernel=kernel_set_file,
    output:
        nb=f"{gwss_results_dir}/notebooks/g123-gwss-{{cohort}}.ipynb",
    log:
        "logs/g123_gwss/{cohort}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p cohort_id {wildcards.cohort} \
        -f {input.config} 2> {log}
        """


rule ihs_gwss:
    """Run the iHS GWSS."""
    input:
        nb=f"{workflow.basedir}/notebooks/ihs-gwss.ipynb",
        cohorts=final_cohorts_file,
        config=workflow_config_file,
        kernel=kernel_set_file,
    output:
        nb=f"{gwss_results_dir}/notebooks/ihs-gwss-{{cohort}}.ipynb",
    log:
        "logs/ihs_gwss/{cohort}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p cohort_id {wildcards.cohort} \
        -f {input.config} 2> {log}
        """

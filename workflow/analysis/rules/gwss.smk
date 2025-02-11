# Expects that variables and functions defined in common-functions.py
# are available.


# TODO not needed?
# def get_h12_calibration_files(wildcards):
#     # df = pd.read_csv(checkpoints.setup_cohorts.get().output.cohorts)
#     df = pd.read_csv(cohorts_file)
#     cohorts = df["cohort_id"]
#     paths = expand(
#         h12_calibration_files,
#         cohort=cohorts,
#     )
#     return paths


# TODO not needed?
# def get_h12_signal_files(wildcards):
#     # df = pd.read_csv(checkpoints.final_cohorts.get().output.final_cohorts)
#     df = pd.read_csv(final_cohorts_file)
#     cohorts = df["cohort_id"]
#     paths = expand(
#         h12_signal_files,
#         cohort=cohorts,
#         contig=contigs,
#     )
#     return paths


def get_gwss_results(wildcards):
    """Collect all expected result files from the GWSS."""

    # df = gpd.read_file(checkpoints.geolocate_cohorts.get().output.final_cohorts_geojson)
    df = pd.read_csv(final_cohorts_file)
    cohorts = df["cohort_id"]

    # Define paths to output files.
    h12_cal_paths = expand(
        h12_calibration_files,
        cohort=cohorts,
    )
    h12_cal_nb_paths = expand(
        f"{analysis_results_dir}/notebooks/h12-calibration-{{cohort}}.ipynb",
        cohort=cohorts,
    )
    h12_gwss_nb_paths = expand(
        f"{analysis_results_dir}/notebooks/h12-gwss-{{cohort}}.ipynb",
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
        f"{analysis_results_dir}/notebooks/g123-calibration-{{cohort}}.ipynb",
        cohort=cohorts,
    )
    g123_gwss_nb_paths = expand(
        f"{analysis_results_dir}/notebooks/g123-gwss-{{cohort}}.ipynb",
        cohort=cohorts,
    )
    ihs_gwss_nb_paths = expand(
        f"{analysis_results_dir}/notebooks/ihs-gwss-{{cohort}}.ipynb",
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


rule h12_calibration:
    """Calibrate the window size for each cohort."""
    input:
        nb=f"{workflow.basedir}/notebooks/h12-calibration.ipynb",
        config=workflow_config_file,
        kernel=kernel_set_file,
    output:
        nb=f"{analysis_results_dir}/notebooks/h12-calibration-{{cohort}}.ipynb",
        calibration=h12_calibration_files,
    log:
        "logs/h12_calibration/{cohort}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas \
        -p cohort_id {wildcards.cohort} -f {input.config} 2> {log}
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
        nb=f"{analysis_results_dir}/notebooks/h12-gwss-{{cohort}}.ipynb",
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
        gwss_nb=f"{analysis_results_dir}/notebooks/h12-gwss-{{cohort}}.ipynb",
        utils_nb=f"{workflow.basedir}/notebooks/peak-utils.ipynb",
        cohorts=final_cohorts_file,
        config=workflow_config_file,
        kernel=kernel_set_file,
    output:
        nb=f"{analysis_results_dir}/notebooks/h12-signal-detection-{{cohort}}-{{contig}}.ipynb",
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
        nb=f"{analysis_results_dir}/notebooks/g123-calibration-{{cohort}}.ipynb",
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
        nb=f"{analysis_results_dir}/notebooks/g123-gwss-{{cohort}}.ipynb",
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
        nb=f"{analysis_results_dir}/notebooks/ihs-gwss-{{cohort}}.ipynb",
    log:
        "logs/ihs_gwss/{cohort}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p cohort_id {wildcards.cohort} \
        -f {input.config} 2> {log}
        """

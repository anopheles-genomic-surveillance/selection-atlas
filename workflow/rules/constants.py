# Common variables and functions for both workflows. Designed so that
# this file can be included into the workflows and also run from within
# a notebook.

# Assume these variables come from the workflow configuration and have
# already been set somehow.
assert isinstance(analysis_version, str)
assert isinstance(contigs, list)

# Path to kernel set flag file.
kernel_set_file = "results/kernel.set"

# Path to main environment file.
environment_file = "workflow/envs/selection-atlas.yaml"

# Paths to analysis workflow results.
analysis_results_dir = f"results/{analysis_version}/analysis"
cohorts_file = f"{analysis_results_dir}/cohorts.csv"
final_cohorts_file = f"{analysis_results_dir}/final_cohorts.csv"
final_cohorts_geojson_file = f"{analysis_results_dir}/final_cohorts.geojson"
h12_calibration_files = f"{analysis_results_dir}/h12-calibration/{{cohort}}.yaml"
h12_signal_files = (
    f"{analysis_results_dir}/h12-signal-detection/{{cohort}}_{{contig}}.csv"
)
g123_calibration_files = f"{analysis_results_dir}/g123-calibration/{{cohort}}.yaml"

# Paths to site workflow results.
site_results_dir = f"results/{analysis_version}/site"
jb_source_dir = f"{site_results_dir}/docs"
jb_build_dir = f"{jb_source_dir}/_build"

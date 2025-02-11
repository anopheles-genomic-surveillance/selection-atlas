
checkpoint setup_cohorts:
    """
    Setup cohorts for analysis using the config file.
    """
    input:
        nb=f"workflow/notebooks/setup-cohorts.ipynb",
        config=config_file,
        kernel="results/kernel.set",
    output:
        nb=f"{analysis_results_dir}/notebooks/setup-cohorts.ipynb",
        cohorts=f"{analysis_results_dir}/cohorts.csv",
    log:
        "logs/setup_cohorts.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -f {input.config} 2> {log}
        """


checkpoint final_cohorts:
    """
    Finalize cohorts for analysis based on the calibration results.
    """
    input:
        yamls=get_h12_calibration_yamls,
        nb=f"workflow/notebooks/final-cohorts.ipynb",
        config=config_file,
        cohorts=f"{analysis_results_dir}/cohorts.csv",
        kernel="results/kernel.set",
    output:
        nb=f"{analysis_results_dir}/notebooks/final-cohorts.ipynb",
        final_cohorts=f"{analysis_results_dir}/final_cohorts.csv",
    log:
        "logs/final_cohorts.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -f {input.config} 2> {log}
        """


checkpoint geolocate_cohorts:
    input:
        nb=f"workflow/notebooks/geolocate-cohorts.ipynb",
        config=config_file,
        final_cohorts=lambda wildcards: checkpoints.final_cohorts.get().output[1],
    output:
        nb=f"{analysis_results_dir}/notebooks/geolocate-cohorts.ipynb",
        cohorts_geojson=f"{analysis_results_dir}/final_cohorts.geojson",
    log:
        "logs/geolocate_cohorts.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -f {input.config} 2> {log}
        """

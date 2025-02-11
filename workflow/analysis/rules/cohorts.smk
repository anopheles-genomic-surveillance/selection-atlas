
checkpoint setup_cohorts:
    """
    Setup cohorts for analysis using the config file.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/setup-cohorts.ipynb",
        config=workflow_config_file,
        kernel=kernel_set_file,
    output:
        nb=f"{analysis_results_dir}/notebooks/setup-cohorts.ipynb",
        cohorts=cohorts_file,
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
        nb=f"{workflow.basedir}/notebooks/final-cohorts.ipynb",
        config=workflow_config_file,
        cohorts=cohorts_file,
        kernel=kernel_set_file,
    output:
        nb=f"{analysis_results_dir}/notebooks/final-cohorts.ipynb",
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
        nb=f"{analysis_results_dir}/notebooks/geolocate-cohorts.ipynb",
        final_cohorts_geojson=final_cohorts_geojson_file,
    log:
        "logs/geolocate_cohorts.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -f {input.config} 2> {log}
        """

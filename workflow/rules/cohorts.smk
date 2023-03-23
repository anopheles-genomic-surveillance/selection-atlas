
checkpoint setup_cohorts:
    """
    Setup cohorts for analysis using the config file.
    """
    input:
        nb = f"{workflow.basedir}/notebooks/setup-cohorts.ipynb",
        config = configpath,
    output:
        nb = "build/notebooks/setup-cohorts.ipynb",
        cohorts = "build/cohorts.csv"
    log:
        "logs/setup_cohorts.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} -f {input.config} 2> {log}
        """

checkpoint final_cohorts:
    """
    Finalize cohorts for analysis based on the calibration results.
    """
    input:
        yamls = get_h12_calibration_yamls,
        nb = f"{workflow.basedir}/notebooks/final-cohorts.ipynb",
        cohorts = "build/cohorts.csv",
    output:
        nb = "build/notebooks/final-cohorts.ipynb",
        final_cohorts = "build/final_cohorts.csv"
    log:
        "logs/final_cohorts.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} 2> {log}
        """

checkpoint geolocate_cohorts:
    input:
        nb = f"{workflow.basedir}/notebooks/geolocate-cohorts.ipynb",
        final_cohorts = lambda wildcards: checkpoints.final_cohorts.get().output[1],
    output:
        nb = "build/notebooks/geolocate-cohorts.ipynb",
        cohorts_geojson = "build/final_cohorts.geojson",
    log:
        "logs/geolocate_cohorts.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} 2> {log}
        """
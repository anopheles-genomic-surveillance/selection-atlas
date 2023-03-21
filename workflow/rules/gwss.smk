
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
        papermill {input.nb} {output.nb} -k selection-atlas -f {input.config} 2> {log}
        """

rule h12_calibration:
    """
    Calibrate the window size for each cohort.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/h12-calibration.ipynb",
        config = configpath
    output:
        nb="build/notebooks/h12-calibration-{cohort}.ipynb",
        yaml = "build/h12-calibration/{cohort}.yaml"
    log:
        "logs/h12_calibration/{cohort}.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
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
        papermill {input.nb} {output.nb} -k selection-atlas 2> {log}
        """


rule h12:
    """
    Run the H12 GWSS
    """
    input:
        template = f"{workflow.basedir}/notebooks/h12-gwss.ipynb",
        window_size = "build/h12-calibration/{cohort}.yaml",
        cohorts = "build/final_cohorts.csv",
        config = configpath
    output:
        nb="build/notebooks/h12-gwss-{cohort}.ipynb"
    log:
        "logs/h12_gwss/{cohort}.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.template} {output.nb} -k selection-atlas -p cohort_id {wildcards.cohort} \
        -f {input.config} 2> {log}
        """

rule h12_signal_detection:
    """
    Detect peaks/signals from the H12 GWSS data 
    """
    input:
        template=f"{workflow.basedir}/notebooks/h12-signal-detection.ipynb",
        gwss_nb="build/notebooks/h12-gwss-{cohort}.ipynb",
        utils_nb=f"{workflow.basedir}/notebooks/peak-utils.ipynb",
        cohorts="build/final_cohorts.csv",
        config = configpath
    output:
        nb="build/notebooks/h12-signal-detection-{cohort}-{contig}.ipynb",
        csv = "build/h12-signal-detection/{cohort}_{contig}.csv"
    log:
        "logs/h12_signal_detection/{cohort}_{contig}.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    params:
    shell:
        """
        papermill {input.template} {output.nb} -k selection-atlas -p cohort_id {wildcards.cohort} -p contig {wildcards.contig} -f {input.config} 2> {log}
        """

# rule ihs:
#     input:
#         template = f"{workflow.basedir}/notebooks/ihs-gwss.ipynb",
#         cohorts = "build/final_cohorts.csv",
#         config = configpath    
#     output:
#         output_nb="build/notebooks/ihs-gwss-{cohort}.ipynb"
#     log:
#         "logs/ihs_gwss/{cohort}.log"
#     conda:
#         f"{workflow.basedir}/../environment.yml"
#     shell:
#         """
#         papermill {input.nb} {output.nb} -k selection-atlas -p cohort_id {wildcards.cohort} -p window_size {params.window_size}
#         """
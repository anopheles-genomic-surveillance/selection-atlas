
rule h12_calibration:
    """
    Calibrate the window size for each cohort.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/h12-calibration.ipynb",
        config = configpath
    output:
        nb="{build_dir}/notebooks/h12-calibration-{cohort}.ipynb",
        yaml = "{build_dir}/h12-calibration/{cohort}.yaml"
    log:
        "logs/h12_calibration/{cohort}.log"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas \
        -p cohort_id {wildcards.cohort} -f {input.config} 2> {log}
        """

rule h12_gwss:
    """
    Run the H12 GWSS
    """
    input:
        template = f"{workflow.basedir}/notebooks/h12-gwss.ipynb",
        window_size = "{build_dir}/h12-calibration/{cohort}.yaml",
        cohorts = "{build_dir}/final_cohorts.csv",
        config = configpath
    output:
        nb="{build_dir}/notebooks/h12-gwss-{cohort}.ipynb"
    log:
        "logs/h12_gwss/{cohort}.log"
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
        gwss_nb="{build_dir}/notebooks/h12-gwss-{cohort}.ipynb",
        utils_nb=f"{workflow.basedir}/notebooks/peak-utils.ipynb",
        cohorts="{build_dir}/final_cohorts.csv",
        config = configpath
    output:
        nb="{build_dir}/notebooks/h12-signal-detection-{cohort}-{contig}.ipynb",
        csv = "{build_dir}/h12-signal-detection/{cohort}_{contig}.csv"
    log:
        "logs/h12_signal_detection/{cohort}_{contig}.log"
    params:
    shell:
        """
        papermill {input.template} {output.nb} -k selection-atlas -p cohort_id {wildcards.cohort} \
         -p contig {wildcards.contig} -f {input.config} 2> {log}
        """


rule g123_calibration:
    """
    Calibrate the window size for each cohort.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/g123-calibration.ipynb",
        config = configpath
    output:
        nb="{build_dir}/notebooks/g123-calibration-{cohort}.ipynb",
        yaml = "{build_dir}/g123-calibration/{cohort}.yaml"
    log:
        "logs/g123_calibration/{cohort}.log"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas \
        -p cohort_id {wildcards.cohort} -f {input.config} 2> {log}
        """

rule g123_gwss:
    """
    Run the g123 GWSS
    """
    input:
        template = f"{workflow.basedir}/notebooks/g123-gwss.ipynb",
        window_size = "{build_dir}/g123-calibration/{cohort}.yaml",
        cohorts = "{build_dir}/final_cohorts.csv",
        config = configpath
    output:
        nb="{build_dir}/notebooks/g123-gwss-{cohort}.ipynb"
    log:
        "logs/g123_gwss/{cohort}.log"
    shell:
        """
        papermill {input.template} {output.nb} -k selection-atlas -p cohort_id {wildcards.cohort} \
        -f {input.config} 2> {log}
        """

rule ihs_gwss:
    """
    Run the iHS GWSS
    """
    input:
        template = f"{workflow.basedir}/notebooks/ihs-gwss.ipynb",
        cohorts = "{build_dir}/final_cohorts.csv",
        config = configpath
    output:
        nb="{build_dir}/notebooks/ihs-gwss-{cohort}.ipynb"
    log:
        "logs/ihs_gwss/{cohort}.log"
    shell:
        """
        papermill {input.template} {output.nb} -k selection-atlas -p cohort_id {wildcards.cohort} \
        -f {input.config} 2> {log}
        """

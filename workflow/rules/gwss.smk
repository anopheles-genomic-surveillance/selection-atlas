
checkpoint setup_cohorts:
    input:
        nb = f"{workflow.basedir}/notebooks/setup-cohorts.ipynb",
        config = "workflow/config.yaml",
        kernel="build/.kernel.set"
    output:
        nb = "build/notebooks/setup-cohorts.ipynb",
        cohorts = "build/cohorts.csv"
    log:
        "logs/setup_cohorts.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas
        """


rule h12_calibration:
    input:
        nb=f"{workflow.basedir}/notebooks/h12-calibration.ipynb",
        kernel="build/.kernel.set"
    output:
        nb="build/notebooks/h12-calibration-{cohort}.ipynb",
        yaml = "build/h12-calibration/{cohort}.yaml"
    log:
        "logs/h12_calibration/{cohort}.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p cohort_id {wildcards.cohort}
        """

checkpoint final_cohorts:
    input:
        yamls = get_h12_calibration_yamls,
        nb = f"{workflow.basedir}/notebooks/final-cohorts.ipynb",
        cohorts = "build/cohorts.csv",
        kernel= "build/.kernel.set"
    output:
        nb = "build/notebooks/final-cohorts.ipynb",
        final_cohorts = "build/final_cohorts.csv"
    log:
        "logs/final_cohorts.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas
        """

rule h12:
    input:
        template = f"{workflow.basedir}/notebooks/h12-gwss.ipynb",
        window_size = "build/h12-calibration/{cohort}.yaml",
        cohorts = "build/final_cohorts.csv"
    output:
        nb="build/notebooks/h12-gwss-{cohort}.ipynb"
    log:
        "logs/h12_gwss/{cohort}.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.template} {output.nb} -k selection-atlas -p cohort_id {wildcards.cohort}
        """

rule h12_signal_detection:
    input:
        template=f"{workflow.basedir}/notebooks/h12-signal-detection.ipynb",
        gwss_nb="build/notebooks/h12-gwss-{cohort}.ipynb",
        cohorts="build/final_cohorts.csv"
    output:
        nb="build/notebooks/h12-signal-detection-{cohort}-{contig}.ipynb",
        csv = "build/h12-signal-detection/{cohort}_{contig}.csv"
    log:
        "logs/h12_signal_detection/{cohort}_{contig}.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.template} {output.nb} -k selection-atlas -p cohort_id {wildcards.cohort} -p contig {wildcards.contig}
        """



rule g123:
    input:
        template=f"{workflow.basedir}/notebooks/g123-gwss.ipynb"
    output:
        nb="build/notebooks/g123-gwss-{cohort}.ipynb"
    log:
        "logs/g123_gwss/{cohort}.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.template} {output.nb} -k selection-atlas -p cohort_id {wildcards.cohort} -p window_size {params.window_size}
        """

rule ihs:
    input:
        template=f"{workflow.basedir}/notebooks/ihs-gwss.ipynb"
    output:
        output_nb="build/notebooks/ihs-gwss-{cohort}.ipynb"
    log:
        "logs/ihs_gwss/{cohort}.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p cohort_id {wildcards.cohort} -p window_size {params.window_size}
        """
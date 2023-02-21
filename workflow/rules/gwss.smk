
checkpoint setup_cohorts:
    input:
        nb = "workflow/notebooks/setup-cohorts.ipynb",
        params = "workflow/params.yaml"
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
        nb="workflow/notebooks/h12-calibration.ipynb"
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
        nb = "workflow/notebooks/final-cohorts.ipynb",
        cohorts = "build/cohorts.csv"
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
        template = "workflow/notebooks/h12-gwss.ipynb",
        window_size = "build/h12-calibration/{cohort}.yaml"
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
        template="workflow/notebooks/h12-signal-detection.ipynb"
    output:
        nb="build/notebooks/h12-signal-detection-{cohort}.ipynb"
    log:
        "logs/h12_signal_detection/{cohort}.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.template} {output.nb} -k selection-atlas -p cohort_id {params.cohort} -p window_size {params.window_size}
        """


rule g123:
    input:
        template="workflow/notebooks/g123-gwss.ipynb"
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
        template="workflow/notebooks/ihs-gwss.ipynb"
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



rule h12_calibration:
    input:
        template="workflows/notebooks/h12-calibration.ipynb"
    output:
        output_nb="build/notebooks/h12-calibration-{cohort}.ipynb",
        yaml = "build/window_sizes/{cohort}.yaml"
    log:
        "logs/h12_calibration/{cohort}.log"
    conda:
        "../environment.yaml"
    params:
    #    cohort=
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p cohort {params.cohort} -p window_size {params.window_size}
        """

checkpoint final_cohorts:
    input:
        expand("build/notebooks/h12-calibration-{cohort}.ipynb" cohort=cohorts)
    output:
        final_cohorts = "final_cohorts.tsv"
    log:
        "logs/final_cohorts.log"
    conda:
        "../environment.yaml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p cohort {params.cohort} -p window_size {params.window_size}
        """

rule h12:
    input:
        template = "workflows/notebooks/h12-gwss.ipynb",
        window_size = "build/window_sizes/{cohort}.yaml"
    output:
        output_nb="build/notebooks/h12-gwss-{cohort}.ipynb"
    log:
        "logs/h12_gwss/{cohort}.log"
    conda:
        "../environment.yaml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p cohort {params.cohort} -p window_size {params.window_size}
        """

rule h12_signal_detection:
    input:
        template="workflows/notebooks/h12-signal-detection.ipynb"
    output:
        output_nb="build/notebooks/h12-signal-detection-{cohort}.ipynb"
    log:
        "logs/h12_signal_detection/{cohort}.log"
    conda:
        "../environment.yaml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p cohort {params.cohort} -p window_size {params.window_size}
        """


rule g123:
    input:
        template="workflows/notebooks/g123-gwss.ipynb"
    output:
        output_nb="build/notebooks/g123-gwss-{cohort}.ipynb"
    log:
        "logs/g123_gwss/{cohort}.log"
    conda:
        "../environment.yaml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p cohort {params.cohort} -p window_size {params.window_size}
        """

rule ihs:
    input:
        template="workflows/notebooks/ihs-gwss.ipynb"
    output:
        output_nb="build/notebooks/ihs-gwss-{cohort}.ipynb"
    log:
        "logs/ihs_gwss/{cohort}.log"
    conda:
        "../environment.yaml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p cohort {params.cohort} -p window_size {params.window_size}
        """
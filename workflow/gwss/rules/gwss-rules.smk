# Rules for the GWSS workflow.
#
# Rules here are declared in roughly the order the are executed.
#
# Assume a `setup` variable has been assigned as an instance of `AtlasSetup`.


checkpoint setup_cohorts:
    """
    Setup cohorts for analysis using the config file. This step reads the sample
    metadata and figures out which cohorts (groups of samples) are going to be
    analysed. The output is a CSV file, one row for each cohort.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/setup-cohorts.ipynb",
        src=setup.gwss_src_files,
        config_file=config_file,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.gwss_results_dir}/notebooks/setup-cohorts.ipynb",
        cohorts=setup.cohorts_file,
    conda:
        setup.environment_file
    log:
        "logs/setup_cohorts.log",
    shell:
        """
        sleep "$((1+RANDOM%20)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} \
            -k selection-atlas \
            -p config_file {input.config_file} \
            &> {log}
        """


rule calibration:
    """
    Calibrate the H12 and G123 window size for each cohort. Note that some cohorts
    may not succeed the calibration process, e.g., if they have extreme demography
    and so a reasonable window size cannot be found.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/calibration.ipynb",
        src=setup.gwss_src_files,
        config_file=config_file,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.gwss_results_dir}/notebooks/calibration-{{cohort}}.ipynb",
        calibration=setup.calibration_files,
    conda:
        setup.environment_file
    log:
        "logs/calibration/{cohort}.log",
    shell:
        """
        sleep "$((1+RANDOM%20)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} \
            -k selection-atlas \
            -p cohort_id {wildcards.cohort} \
            -p config_file {input.config_file} \
            &> {log}
        """


checkpoint finalize_cohorts:
    """
    Finalize cohorts for analysis based on the calibration results. This creates
    a new CSV file of cohorts for which H12 window size calibration succeeded and
    therefore which can be included in GWSS.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/finalize-cohorts.ipynb",
        calibration=get_calibration_files,
        cohorts=lambda wildcards: checkpoints.setup_cohorts.get().output.cohorts,
        src=setup.gwss_src_files,
        config_file=config_file,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.gwss_results_dir}/notebooks/finalize-cohorts.ipynb",
        final_cohorts=setup.final_cohorts_file,
    conda:
        setup.environment_file
    log:
        "logs/final_cohorts.log",
    shell:
        """
        sleep "$((1+RANDOM%20)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} \
            -k selection-atlas \
            -p config_file {input.config_file} \
            &> {log}
        """


rule geolocate_cohorts:
    """
    Add geoboundaries data for each cohort. This allows us to locate cohorts on a
    map.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/geolocate-cohorts.ipynb",
        final_cohorts=lambda wildcards: checkpoints.finalize_cohorts.get().output.final_cohorts,
        src=setup.gwss_src_files,
        config_file=config_file,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.gwss_results_dir}/notebooks/geolocate-cohorts.ipynb",
        final_cohorts_geojson=setup.final_cohorts_geojson_file,
    conda:
        setup.environment_file
    log:
        "logs/geolocate_cohorts.log",
    shell:
        """
        sleep "$((1+RANDOM%20)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} \
            -k selection-atlas \
            -p config_file {input.config_file} \
            &> {log}
        """


rule h12_gwss:
    """
    Run the H12 GWSS.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/h12-gwss.ipynb",
        calibration=setup.calibration_files,
        cohorts=setup.final_cohorts_file,
        src=setup.gwss_src_files,
        config_file=config_file,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.gwss_results_dir}/notebooks/h12-gwss-{{cohort}}.ipynb",
    conda:
        setup.environment_file
    log:
        "logs/h12_gwss/{cohort}.log",
    shell:
        """
        sleep "$((1+RANDOM%20)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} \
            -k selection-atlas \
            -p cohort_id {wildcards.cohort} \
            -p config_file {input.config_file} \
            &> {log}
        """


rule h12_signal_detection:
    """
    Detect peaks/signals from the H12 GWSS data.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/h12-signal-detection.ipynb",
        gwss_nb=f"{setup.gwss_results_dir}/notebooks/h12-gwss-{{cohort}}.ipynb",
        cohorts=setup.final_cohorts_file,
        src=setup.gwss_src_files,
        config_file=config_file,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.gwss_results_dir}/notebooks/h12-signal-detection-{{cohort}}-{{contig}}.ipynb",
        signals=setup.h12_signal_files,
    conda:
        setup.environment_file
    log:
        "logs/h12_signal_detection/{cohort}_{contig}.log",
    shell:
        """
        sleep "$((1+RANDOM%20)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} \
            -k selection-atlas \
            -p cohort_id {wildcards.cohort} \
            -p contig {wildcards.contig} \
            -p config_file {input.config_file} \
            &> {log}
        """


rule g123_gwss:
    """
    Run the G123 GWSS.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/g123-gwss.ipynb",
        calibration=setup.calibration_files,
        cohorts=setup.final_cohorts_file,
        src=setup.gwss_src_files,
        config_file=config_file,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.gwss_results_dir}/notebooks/g123-gwss-{{cohort}}.ipynb",
    conda:
        setup.environment_file
    log:
        "logs/g123_gwss/{cohort}.log",
    shell:
        """
        sleep "$((1+RANDOM%20)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} \
            -k selection-atlas \
            -p cohort_id {wildcards.cohort} \
            -p config_file {input.config_file} \
            &> {log}
        """


rule ihs_gwss:
    """
    Run the iHS GWSS.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/ihs-gwss.ipynb",
        cohorts=setup.final_cohorts_file,
        src=setup.gwss_src_files,
        config_file=config_file,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.gwss_results_dir}/notebooks/ihs-gwss-{{cohort}}.ipynb",
    conda:
        setup.environment_file
    log:
        "logs/ihs_gwss/{cohort}.log",
    shell:
        """
        sleep "$((1+RANDOM%20)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} \
            -k selection-atlas \
            -p cohort_id {wildcards.cohort} \
            -p config_file {input.config_file} \
            &> {log}
        """

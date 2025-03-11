# Rules for the GWSS workflow.
#
# Rules here are declared in roughly the order the are executed.
#
# Assume a `setup` variable has been assigned as an instance of `AtlasSetup`.


rule home_page:
    """
    Generate the home page.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/index-page.ipynb",
        cohorts_geojson=setup.final_cohorts_geojson_file,
        src=setup.site_src_files,
        config_file=config_file,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.site_results_dir}/notebooks/index.ipynb",
    conda:
        setup.environment_file
    log:
        "logs/home_page.log",
    shell:
        """
        sleep "$((1+RANDOM%20)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} \
            -k selection-atlas \
            -p config_file {input.config_file} \
            &> {log}
        """


rule data_sources_page:
    """
    Generate the data sources page.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/data-sources-page.ipynb",
        sample_set_citations=setup.sample_set_citations_file,
        src=setup.site_src_files,
        config_file=config_file,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.site_results_dir}/notebooks/data-sources.ipynb",
    conda:
        setup.environment_file
    log:
        "logs/data_sources_page.log",
    shell:
        """
        sleep "$((1+RANDOM%20)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} \
            -k selection-atlas \
            -p config_file {input.config_file} \
            &> {log}
        """


rule country_pages:
    """
    Generate the country pages.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/country-page.ipynb",
        cohorts_geojson=setup.final_cohorts_geojson_file,
        src=setup.site_src_files,
        config_file=config_file,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.site_results_dir}/notebooks/country/{{country}}.ipynb",
    conda:
        setup.environment_file
    log:
        "logs/country_pages/{country}.log",
    shell:
        """
        sleep "$((1+RANDOM%20)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} \
            -k selection-atlas \
            -p country {wildcards.country} \
            -p config_file {input.config_file} \
            &> {log}
        """


rule contig_pages:
    """
    Generate the contig pages.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/contig-page.ipynb",
        cohorts_geojson=setup.final_cohorts_geojson_file,
        signals=get_h12_signal_files,
        src=setup.site_src_files,
        config_file=config_file,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.site_results_dir}/notebooks/contig/{{contig}}.ipynb",
    conda:
        setup.environment_file
    log:
        "logs/contig_pages/{contig}.log",
    shell:
        """
        sleep "$((1+RANDOM%20)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} \
            -k selection-atlas \
            -p contig {wildcards.contig} \
            -p config_file {input.config_file} \
            &> {log}
        """


rule cohort_pages:
    """
    Generate the cohort pages.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/cohort-page.ipynb",
        cohorts_geojson=setup.final_cohorts_geojson_file,
        sample_set_citations=setup.sample_set_citations_file,
        h12_gwss=f"{setup.gwss_results_dir}/notebooks/h12-gwss-{{cohort}}.ipynb",
        g123_gwss=f"{setup.gwss_results_dir}/notebooks/g123-gwss-{{cohort}}.ipynb",
        ihs_gwss=f"{setup.gwss_results_dir}/notebooks/ihs-gwss-{{cohort}}.ipynb",
        signals=get_h12_signal_files,
        src=setup.site_src_files,
        config_file=config_file,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.site_results_dir}/notebooks/cohort/{{cohort}}.ipynb",
    conda:
        setup.environment_file
    log:
        "logs/cohort_pages/{cohort}.log",
    shell:
        """
        sleep "$((1+RANDOM%20)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} \
            -k selection-atlas \
            -p cohort_id {wildcards.cohort} \
            -p config_file {input.config_file} \
            &> {log}
        """


rule alert_pages:
    """
    Generate the alert pages.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/alert-page.ipynb",
        cohorts_geojson=setup.final_cohorts_geojson_file,
        alert_config=f"{setup.alerts_dir}/{{alert}}.yaml",
        signals=get_h12_signal_files,
        src=setup.site_src_files,
        config_file=config_file,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.site_results_dir}/notebooks/alert/{{alert}}.ipynb",
    conda:
        setup.environment_file
    log:
        "logs/alert_pages/{alert}.log",
    shell:
        """
        sleep "$((1+RANDOM%20)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} \
            -k selection-atlas \
            -p alert_id {wildcards.alert} \
            -p config_file {input.config_file} \
            &> {log}
        """


rule postprocess_page:
    """
    Process a notebook to fix page titles and remove papermill parameters.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/postprocess-page.ipynb",
        page_nb=f"{setup.site_results_dir}/notebooks/{{page}}.ipynb",
        src=setup.site_src_files,
        config_file=config_file,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.site_results_dir}/notebooks/postprocess-page/{{page}}.ipynb",
        page_nb=f"{setup.jb_source_dir}/{{page}}.ipynb",
    conda:
        setup.environment_file
    log:
        "logs/postprocess-page/{page}.log",
    shell:
        """
        sleep "$((1+RANDOM%20)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} \
            -k selection-atlas \
            -p input_nb {input.page_nb} \
            -p output_nb {output.page_nb} \
            -p config_file {input.config_file} \
            &> {log}
        """


rule generate_jb_toc:
    """
    Generate the table of contents for the Jupyter book.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/generate-toc.ipynb",
        cohorts_geojson=setup.final_cohorts_geojson_file,
        src=setup.site_src_files,
        config_file=config_file,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.site_results_dir}/notebooks/generate-toc.ipynb",
        jb_toc=f"{setup.jb_source_dir}/_toc.yml",
    conda:
        setup.environment_file
    log:
        "logs/generate_jb_toc.log",
    shell:
        """
        sleep "$((1+RANDOM%20)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} \
            -k selection-atlas \
            -p config_file {input.config_file} \
            &> {log}
        """


rule generate_jb_config:
    """
    Generate the config for the Jupyter book.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/generate-config.ipynb",
        src=setup.site_src_files,
        config_file=config_file,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.site_results_dir}/notebooks/generate-config.ipynb",
        jb_config=f"{setup.jb_source_dir}/_config.yml",
    conda:
        setup.environment_file
    log:
        "logs/generate_jb_config.log",
    shell:
        """
        sleep "$((1+RANDOM%20)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} \
            -k selection-atlas \
            -p config_file {input.config_file} \
            &> {log}
        """


rule prepare_site:
    """
    Copy static files to the staging area, in preparation for running
    the Jupyter book build.
    """
    input:
        [f"{workflow.basedir}/docs/{p}" for p in setup.static_site_files],
    output:
        [f"{setup.jb_source_dir}/{p}" for p in setup.static_site_files],
    conda:
        setup.environment_file
    log:
        "logs/prepare_site.log",
    shell:
        f"""
        mkdir -pv {setup.jb_source_dir}
        cp -rv {workflow.basedir}/docs/* {setup.jb_source_dir}/
        """


rule compile_site:
    """
    Run the Jupyter book build.
    """
    input:
        get_selection_atlas_site_files,
        src=setup.site_src_files,
        config_file=config_file,
        kernel=setup.kernel_set_file,
    output:
        directory(setup.jb_build_dir),
    conda:
        setup.environment_file
    log:
        "logs/compile_site.log",
    shell:
        f"""
        jupyter-book build {setup.jb_source_dir}
        """

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
        nb=f"{workflow.basedir}/notebooks/index.ipynb",
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
            -f {input.alert_config} &> {log}
        """


rule process_headers_home:
    """
    Process the home page to fix page titles and remove papermill parameters.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/add-headers.ipynb",
        homepage_nb=f"{setup.site_results_dir}/notebooks/index.ipynb",
        src=setup.site_src_files,
        config_file=config_file,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.site_results_dir}/notebooks/add_headers/index.ipynb",
        homepage_nb=f"{setup.jb_source_dir}/index.ipynb",
    conda:
        setup.environment_file
    log:
        "logs/add_headers/home-page.log",
    shell:
        """
        sleep "$((1+RANDOM%20)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} \
            -k selection-atlas \
            -p input_nb {input.homepage_nb} \
            -p output_nb {output.homepage_nb} \
            -p page_type homepage \
            -p config_file {input.config_file} \
            &> {log}
        """


rule process_headers_contig:
    """
    Process the contig pages to fix page titles and remove papermill parameters.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/add-headers.ipynb",
        contig_nb=f"{setup.site_results_dir}/notebooks/contig/ag-{{contig}}.ipynb",
        src=setup.site_src_files,
        config_file=config_file,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.site_results_dir}/notebooks/add_headers/contig-{{contig}}.ipynb",
        contig_nb=f"{setup.jb_source_dir}/contig/{{contig}}.ipynb",
    conda:
        setup.environment_file
    log:
        "logs/add_headers/contig-{contig}.log",
    shell:
        """
        sleep "$((1+RANDOM%20)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} \
            -k selection-atlas \
            -p input_nb {input.contig_nb} \
            -p output_nb {output.contig_nb} \
            -p wildcard {wildcards.contig} \
            -p page_type contig \
            -p config_file {input.config_file} \
            &> {log}
        """


rule process_headers_country:
    """
    Process the country pages to fix page titles and remove papermill parameters.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/add-headers.ipynb",
        country_nb=f"{setup.site_results_dir}/notebooks/country/{{country}}.ipynb",
        src=setup.site_src_files,
        config_file=config_file,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.site_results_dir}/notebooks/add_headers/country-{{country}}.ipynb",
        country_nb=f"{setup.jb_source_dir}/country/{{country}}.ipynb",
    conda:
        setup.environment_file
    log:
        "logs/add_headers/country-{country}.log",
    shell:
        """
        sleep "$((1+RANDOM%20)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} \
            -k selection-atlas \
            -p input_nb {input.country_nb} \
            -p output_nb {output.country_nb} \
            -p wildcard {wildcards.country} \
            -p page_type country \
            -p config_file {input.config_file} \
            &> {log}
        """


rule process_headers_cohort:
    """
    Process the cohort pages to fix page titles and remove papermill parameters.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/add-headers.ipynb",
        cohort_nb=f"{setup.site_results_dir}/notebooks/cohort/{{cohort}}.ipynb",
        src=setup.site_src_files,
        config_file=config_file,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.site_results_dir}/notebooks/add_headers/cohort-{{cohort}}.ipynb",
        cohort_nb=f"{setup.jb_source_dir}/cohort/{{cohort}}.ipynb",
    conda:
        setup.environment_file
    log:
        "logs/add_headers/cohort-{cohort}.log",
    shell:
        """
        sleep "$((1+RANDOM%20)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} \
            -k selection-atlas \
            -p input_nb {input.cohort_nb} \
            -p output_nb {output.cohort_nb} \
            -p wildcard {wildcards.cohort} \
            -p page_type cohort \
            -p config_file {input.config_file} \
            &> {log}
        """


rule process_headers_alert:
    """
    Process the alert pages to fix page titles and remove papermill parameters.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/add-headers.ipynb",
        alert_nb=f"{setup.site_results_dir}/notebooks/alert/{{alert}}.ipynb",
        src=setup.site_src_files,
        config_file=config_file,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.site_results_dir}/notebooks/add_headers/alert-{{alert}}.ipynb",
        alert_nb=f"{setup.jb_source_dir}/alert/{{alert}}.ipynb",
    conda:
        setup.environment_file
    log:
        "logs/add_headers/alert-{alert}.log",
    shell:
        """
        sleep "$((1+RANDOM%20)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} \
            -k selection-atlas \
            -p input_nb {input.alert_nb} \
            -p output_nb {output.alert_nb} \
            -p wildcard {wildcards.alert} \
            -p page_type alert \
            -p config_file {input.config_file} \
            &> {log}
        """


rule generate_toc:
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
        toc=f"{setup.jb_source_dir}/_toc.yml",
    conda:
        setup.environment_file
    log:
        "logs/generate_toc.log",
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

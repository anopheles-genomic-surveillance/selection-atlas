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
        site_utils=f"{workflow.basedir}/scripts/page-setup.py",
        nb=f"{workflow.basedir}/notebooks/home-page.ipynb",
        config=workflow.configfiles,
        cohorts_geojson=setup.final_cohorts_geojson_file,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.site_results_dir}/notebooks/home-page.ipynb",
    conda:
        setup.environment_file
    log:
        "logs/home_page.log",
    shell:
        """
        sleep "$((1+RANDOM%10)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} -k selection-atlas -f {input.config} 2> {log}
        """


rule country_pages:
    """
    Generate the country pages.
    """
    input:
        site_utils=f"{workflow.basedir}/scripts/page-setup.py",
        nb=f"{workflow.basedir}/notebooks/country-page.ipynb",
        config=workflow.configfiles,
        cohorts_geojson=setup.final_cohorts_geojson_file,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.site_results_dir}/notebooks/country/{{country}}.ipynb",
    conda:
        setup.environment_file
    log:
        "logs/country_pages/{country}.log",
    shell:
        """
        sleep "$((1+RANDOM%10)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} -k selection-atlas -p country {wildcards.country} -f {input.config} 2> {log}
        """


rule contig_pages:
    """
    Generate the contig pages.
    """
    input:
        site_utils=f"{workflow.basedir}/scripts/page-setup.py",
        nb=f"{workflow.basedir}/notebooks/contig-page.ipynb",
        config=workflow.configfiles,
        cohorts_geojson=setup.final_cohorts_geojson_file,
        signals=get_h12_signal_files,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.site_results_dir}/notebooks/contig/{{contig}}.ipynb",
    conda:
        setup.environment_file
    log:
        "logs/contig_pages/{contig}.log",
    shell:
        """
        sleep "$((1+RANDOM%10)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} -k selection-atlas -p contig {wildcards.contig} -f {input.config} 2> {log}
        """


rule cohort_pages:
    """
    Generate the cohort pages.
    """
    input:
        site_utils=f"{workflow.basedir}/scripts/page-setup.py",
        nb=f"{workflow.basedir}/notebooks/cohort-page.ipynb",
        cohorts_geojson=setup.final_cohorts_geojson_file,
        h12_gwss=f"{setup.gwss_results_dir}/notebooks/h12-gwss-{{cohort}}.ipynb",
        g123_gwss=f"{setup.gwss_results_dir}/notebooks/g123-gwss-{{cohort}}.ipynb",
        ihs_gwss=f"{setup.gwss_results_dir}/notebooks/ihs-gwss-{{cohort}}.ipynb",
        signals=get_h12_signal_files,
        config=workflow.configfiles,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.site_results_dir}/notebooks/cohort/{{cohort}}.ipynb",
    conda:
        setup.environment_file
    log:
        "logs/cohort_pages/{cohort}.log",
    shell:
        """
        sleep "$((1+RANDOM%10)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} -k selection-atlas -p cohort_id {wildcards.cohort} -f {input.config} 2> {log}
        """


rule alert_pages:
    """
    Generate the alert pages.
    """
    input:
        site_utils=f"{workflow.basedir}/scripts/page-setup.py",
        nb=f"{workflow.basedir}/notebooks/alert-page.ipynb",
        cohorts_geojson=setup.final_cohorts_geojson_file,
        alert_config=f"{setup.alerts_dir}/{{alert}}.yaml",
        signals=get_h12_signal_files,
        config=workflow.configfiles,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.site_results_dir}/notebooks/alert/{{alert}}.ipynb",
    conda:
        setup.environment_file
    log:
        "logs/alert_pages/{alert}.log",
    shell:
        """
        sleep "$((1+RANDOM%10)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} -k selection-atlas -p alert_id {wildcards.alert} -f {input.config} -f {input.alert_config} 2> {log}
        """


rule process_headers_home:
    """
    Process the home page to fix page titles and remove papermill parameters.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/add-headers.ipynb",
        homepage_nb=f"{setup.site_results_dir}/notebooks/home-page.ipynb",
        config=workflow.configfiles,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.site_results_dir}/notebooks/add_headers/home-page.ipynb",
        homepage_nb=f"{setup.site_results_dir}/docs/index.ipynb",
    conda:
        setup.environment_file
    log:
        "logs/add_headers/home-page.log",
    shell:
        """
        sleep "$((1+RANDOM%10)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} \
            -k selection-atlas \
            -p input_nb {input.homepage_nb} \
            -p output_nb {output.homepage_nb} \
            -p page_type homepage \
            -f {input.config} \
            2> {log}
        """


rule process_headers_contig:
    """
    Process the contig pages to fix page titles and remove papermill parameters.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/add-headers.ipynb",
        contig_nb=f"{setup.site_results_dir}/notebooks/contig/ag-{{contig}}.ipynb",
        config=workflow.configfiles,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.site_results_dir}/notebooks/add_headers/{{contig}}.ipynb",
        contig_nb=f"{setup.site_results_dir}/docs/contig/ag-{{contig}}.ipynb",
    conda:
        setup.environment_file
    log:
        "logs/add_headers/contig-{contig}.log",
    shell:
        """
        sleep "$((1+RANDOM%10)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} \
            -k selection-atlas \
            -p input_nb {input.contig_nb} \
            -p output_nb {output.contig_nb} \
            -p wildcard {wildcards.contig} \
            -p page_type contig \
            -f {input.config} \
            2> {log}
        """


rule process_headers_country:
    """
    Process the country pages to fix page titles and remove papermill parameters.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/add-headers.ipynb",
        country_nb=f"{setup.site_results_dir}/notebooks/country/{{country}}.ipynb",
        config=workflow.configfiles,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.site_results_dir}/notebooks/add_headers/{{country}}.ipynb",
        country_nb=f"{setup.site_results_dir}/docs/country/{{country}}.ipynb",
    conda:
        setup.environment_file
    log:
        "logs/add_headers/country-{country}.log",
    shell:
        """
        sleep "$((1+RANDOM%10)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} \
            -k selection-atlas \
            -p input_nb {input.country_nb} \
            -p output_nb {output.country_nb} \
            -p wildcard {wildcards.country} \
            -p page_type country \
            -f {input.config} \
            2> {log}
        """


rule process_headers_cohort:
    """
    Process the cohort pages to fix page titles and remove papermill parameters.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/add-headers.ipynb",
        cohort_nb=f"{setup.site_results_dir}/notebooks/cohort/{{cohort}}.ipynb",
        config=workflow.configfiles,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.site_results_dir}/notebooks/add_headers/{{cohort}}.ipynb",
        cohort_nb=f"{setup.site_results_dir}/docs/cohort/{{cohort}}.ipynb",
    conda:
        setup.environment_file
    log:
        "logs/add_headers/cohort-{cohort}.log",
    shell:
        """
        sleep "$((1+RANDOM%10)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} \
            -k selection-atlas \
            -p input_nb {input.cohort_nb} \
            -p output_nb {output.cohort_nb} \
            -p wildcard {wildcards.cohort} \
            -p page_type cohort \
            -f {input.config} \
            2> {log}
        """


rule process_headers_alert:
    """
    Process the alert pages to fix page titles and remove papermill parameters.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/add-headers.ipynb",
        alert_nb=f"{setup.site_results_dir}/notebooks/alert/{{alert}}.ipynb",
        config=workflow.configfiles,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.site_results_dir}/notebooks/add_headers/{{alert}}.ipynb",
        alert_nb=f"{setup.site_results_dir}/docs/alert/{{alert}}.ipynb",
    conda:
        setup.environment_file
    log:
        "logs/add_headers/alert-{alert}.log",
    shell:
        """
        sleep "$((1+RANDOM%10)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} \
            -k selection-atlas \
            -p input_nb {input.alert_nb} \
            -p output_nb {output.alert_nb} \
            -p wildcard {wildcards.alert} \
            -p page_type alert \
            -f {input.config} \
            2> {log}
        """


rule generate_toc:
    """
    Generate the table of contents for the Jupyter book.
    """
    input:
        site_utils=f"{workflow.basedir}/scripts/page-setup.py",
        nb=f"{workflow.basedir}/notebooks/generate-toc.ipynb",
        cohorts_geojson=setup.final_cohorts_geojson_file,
        config=workflow.configfiles,
        kernel=setup.kernel_set_file,
    output:
        nb=f"{setup.site_results_dir}/notebooks/generate-toc.ipynb",
        toc=f"{setup.site_results_dir}/docs/_toc.yml",
    conda:
        setup.environment_file
    log:
        "logs/generate_toc.log",
    shell:
        """
        sleep "$((1+RANDOM%10)).$((RANDOM%999))"
        papermill {input.nb} {output.nb} -k selection-atlas -f {input.config} 2> {log}
        """


rule prepare_site:
    """
    Copy static files to the staging area, in preparation for running
    the Jupyter book build.
    """
    input:
        [f"{workflow.basedir}/docs/{p}" for p in static_site_files],
    output:
        [f"{setup.site_results_dir}/docs/{p}" for p in static_site_files],
    conda:
        setup.environment_file
    log:
        "logs/prepare_site.log",
    shell:
        f"""
        mkdir -pv {setup.site_results_dir}/docs/
        cp -rv {workflow.basedir}/docs/* {setup.site_results_dir}/docs/
        """


rule compile_site:
    """
    Run the Jupyter book build.
    """
    input:
        get_selection_atlas_site_files,
        config=workflow.configfiles,
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

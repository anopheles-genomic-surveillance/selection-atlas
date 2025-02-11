# Expects that variables and functions defined in workflow/scripts/setup.py
# are available.


rule home_page:
    """
    Generate the home page.
    """
    input:
        site_utils=f"{workflow.basedir}/scripts/page-setup.py",
        nb=f"{workflow.basedir}/notebooks/home-page.ipynb",
        config=workflow_config_file,
        cohorts_geojson=final_cohorts_geojson_file,
        kernel=kernel_set_file,
    output:
        nb=f"{site_results_dir}/notebooks/home-page.ipynb",
    log:
        "logs/home_page.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -f {input.config} 2> {log}
        """


rule country_pages:
    """
    Generate the country pages.
    """
    input:
        site_utils=f"{workflow.basedir}/scripts/page-setup.py",
        nb=f"{workflow.basedir}/notebooks/country-page.ipynb",
        config=workflow_config_file,
        cohorts_geojson=final_cohorts_geojson_file,
        kernel=kernel_set_file,
    output:
        nb=f"{site_results_dir}/notebooks/country/{{country}}.ipynb",
    log:
        "logs/country_pages/{country}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p country {wildcards.country} -f {input.config} 2> {log}
        """


rule contig_pages:
    """
    Generate the contig pages.
    """
    input:
        site_utils=f"{workflow.basedir}/scripts/page-setup.py",
        nb=f"{workflow.basedir}/notebooks/contig-page.ipynb",
        config=workflow_config_file,
        cohorts_geojson=final_cohorts_geojson_file,
        signals=get_h12_signal_files,
        kernel=kernel_set_file,
    output:
        nb=f"{site_results_dir}/notebooks/contig/ag-{{contig}}.ipynb",
    log:
        "logs/contig_pages/{contig}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p contig {wildcards.contig} -f {input.config} 2> {log}
        """


rule cohort_pages:
    """
    Generate the cohort pages.
    """
    input:
        site_utils=f"{workflow.basedir}/scripts/page-setup.py",
        nb=f"{workflow.basedir}/notebooks/cohort-page.ipynb",
        cohorts_geojson=final_cohorts_geojson_file,
        h12_gwss=f"{gwss_results_dir}/notebooks/h12-gwss-{{cohort}}.ipynb",
        g123_gwss=f"{gwss_results_dir}/notebooks/g123-gwss-{{cohort}}.ipynb",
        ihs_gwss=f"{gwss_results_dir}/notebooks/ihs-gwss-{{cohort}}.ipynb",
        signals=get_h12_signal_files,
        config=workflow_config_file,
        kernel=kernel_set_file,
    output:
        nb=f"{site_results_dir}/notebooks/cohort/{{cohort}}.ipynb",
    log:
        "logs/cohort_pages/{cohort}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p cohort_id {wildcards.cohort} -f {input.config} 2> {log}
        """


rule alert_pages:
    """
    Generate the alert pages.
    """
    input:
        site_utils=f"{workflow.basedir}/scripts/page-setup.py",
        nb=f"{workflow.basedir}/notebooks/alert-page.ipynb",
        cohorts_geojson=final_cohorts_geojson_file,
        alert_config=f"{workflow.basedir}/alerts/{{alert}}.yaml",
        signals=get_h12_signal_files,
        config=workflow_config_file,
        kernel=kernel_set_file,
    output:
        nb=f"{site_results_dir}/notebooks/alert/{{alert}}.ipynb",
    log:
        "logs/alert_pages/{alert}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p alert_id {wildcards.alert} -f {input.config} -f {input.alert_config} 2> {log}
        """


rule process_headers_home:
    """
    Process the home page to fix page titles and remove papermill parameters.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/add-headers.ipynb",
        homepage_nb=f"{site_results_dir}/notebooks/home-page.ipynb",
        kernel=kernel_set_file,
    output:
        nb=f"{site_results_dir}/notebooks/add_headers/home-page.ipynb",
        homepage_nb=f"{site_results_dir}/docs/home-page.ipynb",
    log:
        "logs/add_headers/home-page.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p input_nb {input.homepage_nb} -p output_nb {output.homepage_nb} -p page_type homepage -p analysis_version {analysis_version} 2> {log}
        """


rule process_headers_contig:
    """
    Process the contig pages to fix page titles and remove papermill parameters.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/add-headers.ipynb",
        contig_nb=f"{site_results_dir}/notebooks/contig/ag-{{contig}}.ipynb",
        kernel=kernel_set_file,
    output:
        nb=f"{site_results_dir}/notebooks/add_headers/{{contig}}.ipynb",
        contig_nb=f"{site_results_dir}/docs/contig/ag-{{contig}}.ipynb",
    log:
        "logs/add_headers/contig-{contig}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p input_nb {input.contig_nb} -p output_nb {output.contig_nb} -p wildcard {wildcards.contig} -p page_type contig -p analysis_version {analysis_version} 2> {log}
        """


rule process_headers_country:
    """
    Process the country pages to fix page titles and remove papermill parameters.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/add-headers.ipynb",
        country_nb=f"{site_results_dir}/notebooks/country/{{country}}.ipynb",
        kernel=kernel_set_file,
    output:
        nb=f"{site_results_dir}/notebooks/add_headers/{{country}}.ipynb",
        country_nb=f"{site_results_dir}/docs/country/{{country}}.ipynb",
    log:
        "logs/add_headers/country-{country}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p input_nb {input.country_nb} -p output_nb {output.country_nb} -p wildcard {wildcards.country} -p page_type country -p analysis_version {analysis_version} 2> {log}
        """


rule process_headers_cohort:
    """
    Process the cohort pages to fix page titles and remove papermill parameters.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/add-headers.ipynb",
        cohort_nb=f"{site_results_dir}/notebooks/cohort/{{cohort}}.ipynb",
        kernel=kernel_set_file,
    output:
        nb=f"{site_results_dir}/notebooks/add_headers/{{cohort}}.ipynb",
        cohort_nb=f"{site_results_dir}/docs/cohort/{{cohort}}.ipynb",
    log:
        "logs/add_headers/cohort-{cohort}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p input_nb {input.cohort_nb} -p output_nb {output.cohort_nb} -p wildcard {wildcards.cohort} -p page_type cohort -p analysis_version {analysis_version} 2> {log}
        """


rule process_headers_alert:
    """
    Process the alert pages to fix page titles and remove papermill parameters.
    """
    input:
        nb=f"{workflow.basedir}/notebooks/add-headers.ipynb",
        alert_nb=f"{site_results_dir}/notebooks/alert/{{alert}}.ipynb",
        kernel=kernel_set_file,
    output:
        nb=f"{site_results_dir}/notebooks/add_headers/{{alert}}.ipynb",
        alert_nb=f"{site_results_dir}/docs/alert/{{alert}}.ipynb",
    log:
        "logs/add_headers/alert-{alert}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p input_nb {input.alert_nb} -p output_nb {output.alert_nb} -p wildcard {wildcards.alert} -p page_type alert -p analysis_version {analysis_version} 2> {log}
        """


rule generate_toc:
    """
    Generate the table of contents for the Jupyter book.
    """
    input:
        site_utils=f"{workflow.basedir}/scripts/page-setup.py",
        nb=f"{workflow.basedir}/notebooks/generate-toc.ipynb",
        cohorts_geojson=final_cohorts_geojson_file,
        config=workflow_config_file,
        kernel=kernel_set_file,
    output:
        nb=f"{site_results_dir}/notebooks/generate-toc.ipynb",
        toc=f"{site_results_dir}/docs/_toc.yml",
    log:
        "logs/generate_toc.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -f {input.config} 2> {log}
        """


rule prepare_site:
    """
    Copy static files to the staging area, in preparation for running
    the Jupyter book build.
    """
    input:
        f"{workflow.basedir}/docs/_config.yml",
        f"{workflow.basedir}/docs/alerts.ipynb",
        f"{workflow.basedir}/docs/favicon.ico",
    output:
        f"{site_results_dir}/docs/_config.yml",
        f"{site_results_dir}/docs/alerts.ipynb",
        f"{site_results_dir}/docs/favicon.ico",
    shell:
        f"""
        mkdir -pv {site_results_dir}/docs/
        cp -rv {workflow.basedir}/docs/* {site_results_dir}/docs/
        """


rule compile_site:
    """
    Run the Jupyter book build.
    """
    input:
        get_selection_atlas_site_files,
        config=workflow_config_file,
        kernel=kernel_set_file,
    output:
        directory(jb_build_dir),
    log:
        "logs/compile_site.log",
    shell:
        f"""
        jupyter-book build {jb_source_dir}
        """

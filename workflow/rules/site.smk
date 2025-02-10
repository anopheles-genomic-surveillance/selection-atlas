rule build_site:
    input:
        get_selection_atlas_site_files,
        config=configpath,
    output:
        directory(f"{site_dir}/docs/_build"),
    log:
        "logs/build-jupyter-book.log",
    shell:
        f"""
        jupyter-book build {site_dir}/docs
        """


rule prepare_site:
    output:
        f"{site_dir}/docs/_config.yml",
        f"{site_dir}/docs/alerts.ipynb",
        f"{site_dir}/docs/favicon.ico",
    input:
        f"{workflow.basedir}/docs/_config.yml",
        f"{workflow.basedir}/docs/alerts.ipynb",
        f"{workflow.basedir}/docs/favicon.ico",
    shell:
        f"""
        mkdir -pv {site_dir}/docs/
        cp -rv {workflow.basedir}/docs/* {site_dir}/docs/
        """


rule generate_toc:
    input:
        site_utils=f"{workflow.basedir}/notebooks/site-utils.py",
        nb=f"{workflow.basedir}/notebooks/generate-toc.ipynb",
        cohorts_geojson=f"{analysis_dir}/final_cohorts.geojson",
        config=configpath,
        kernel=".kernel.set",
    output:
        nb=f"{site_dir}/notebooks/generate-toc.ipynb",
        toc=f"{site_dir}/docs/_toc.yml",
    log:
        "logs/generate_toc.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -f {input.config} 2> {log}
        """


rule home_page:
    input:
        site_utils=f"{workflow.basedir}/notebooks/site-utils.py",
        nb=f"{workflow.basedir}/notebooks/home-page.ipynb",
        config=configpath,
        cohorts_geojson=f"{analysis_dir}/final_cohorts.geojson",
        kernel=".kernel.set",
    output:
        nb=f"{site_dir}/notebooks/home-page.ipynb",
    log:
        "logs/home_page.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -f {input.config} 2> {log}
        """


rule country_pages:
    input:
        site_utils=f"{workflow.basedir}/notebooks/site-utils.py",
        nb=f"{workflow.basedir}/notebooks/country-page.ipynb",
        config=configpath,
        cohorts_geojson=f"{analysis_dir}/final_cohorts.geojson",
        kernel=".kernel.set",
    output:
        nb=f"{site_dir}/notebooks/country/{{country}}.ipynb",
    log:
        "logs/country_pages/{country}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p country {wildcards.country} -f {input.config} 2> {log}
        """


rule chromosome_pages:
    input:
        site_utils=f"{workflow.basedir}/notebooks/site-utils.py",
        nb=f"{workflow.basedir}/notebooks/chromosome-page.ipynb",
        config=configpath,
        cohorts_geojson=f"{analysis_dir}/final_cohorts.geojson",
        signals=get_h12_signal_detection_csvs,
        kernel=".kernel.set",
    output:
        nb=f"{site_dir}/notebooks/genome/ag-{{chrom}}.ipynb",
    log:
        "logs/chromosome_pages/{chrom}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p contig {wildcards.chrom} -f {input.config} 2> {log}
        """


rule cohort_pages:
    input:
        site_utils=f"{workflow.basedir}/notebooks/site-utils.py",
        nb=f"{workflow.basedir}/notebooks/cohort-page.ipynb",
        cohorts_geojson=f"{analysis_dir}/final_cohorts.geojson",
        output_h12=f"{analysis_dir}/notebooks/h12-gwss-{{cohort}}.ipynb",
        output_g123=f"{analysis_dir}/notebooks/g123-gwss-{{cohort}}.ipynb",
        output_ihs=f"{analysis_dir}/notebooks/ihs-gwss-{{cohort}}.ipynb",
        config=configpath,
        signals=expand(
            "{analysis_dir}/h12-signal-detection/{{cohort}}_{contig}.csv",
            contig=chromosomes,
            analysis_dir=analysis_dir,
        ),
        kernel=".kernel.set",
    output:
        nb=f"{site_dir}/notebooks/cohort/{{cohort}}.ipynb",
    log:
        "logs/cohort_pages/{cohort}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p cohort_id {wildcards.cohort} -f {input.config} 2> {log}
        """


rule alert_pages:
    input:
        site_utils=f"{workflow.basedir}/notebooks/site-utils.py",
        nb=f"{workflow.basedir}/notebooks/alert-page.ipynb",
        cohorts_geojson=f"{analysis_dir}/final_cohorts.geojson",
        config=configpath,
        alert_config=f"{workflow.basedir}/alerts/{{alert}}.yaml",
        signals=get_h12_signal_detection_csvs,
        kernel=".kernel.set",
    output:
        nb=f"{site_dir}/notebooks/alert/{{alert}}.ipynb",
    log:
        "logs/alert_pages/{alert}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p alert_id {wildcards.alert} -f {input.config} -f {input.alert_config} 2> {log}
        """


rule process_headers_home:
    input:
        nb="workflow/notebooks/add-headers.ipynb",
        homepage_nb=f"{site_dir}/notebooks/home-page.ipynb",
        kernel=".kernel.set",
    output:
        nb=f"{site_dir}/notebooks/add_headers/home-page.ipynb",
        homepage_nb=f"{site_dir}/docs/home-page.ipynb",
    log:
        "logs/add_headers/home-page.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p input_nb {input.homepage_nb} -p output_nb {output.homepage_nb} -p page_type homepage -p analysis_version {analysis_version} 2> {log}
        """


rule process_headers_chrom:
    input:
        nb="workflow/notebooks/add-headers.ipynb",
        chrom_nb=f"{site_dir}/notebooks/genome/ag-{{contig}}.ipynb",
        kernel=".kernel.set",
    output:
        nb=f"{site_dir}/notebooks/add_headers/{{contig}}.ipynb",
        chrom_nb=f"{site_dir}/docs/genome/ag-{{contig}}.ipynb",
    log:
        "logs/add_headers/chrom-{contig}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p input_nb {input.chrom_nb} -p output_nb {output.chrom_nb} -p wildcard {wildcards.contig} -p page_type chrom -p analysis_version {analysis_version} 2> {log}
        """


rule process_headers_country:
    input:
        nb="workflow/notebooks/add-headers.ipynb",
        country_nb=f"{site_dir}/notebooks/country/{{country}}.ipynb",
        kernel=".kernel.set",
    output:
        nb=f"{site_dir}/notebooks/add_headers/{{country}}.ipynb",
        country_nb=f"{site_dir}/docs/country/{{country}}.ipynb",
    log:
        "logs/add_headers/country-{country}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p input_nb {input.country_nb} -p output_nb {output.country_nb} -p wildcard {wildcards.country} -p page_type country -p analysis_version {analysis_version} 2> {log}
        """


rule process_headers_cohort:
    input:
        nb="workflow/notebooks/add-headers.ipynb",
        cohort_nb=f"{site_dir}/notebooks/cohort/{{cohort}}.ipynb",
        kernel=".kernel.set",
    output:
        nb=f"{site_dir}/notebooks/add_headers/{{cohort}}.ipynb",
        cohort_nb=f"{site_dir}/docs/cohort/{{cohort}}.ipynb",
    log:
        "logs/add_headers/cohort-{cohort}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p input_nb {input.cohort_nb} -p output_nb {output.cohort_nb} -p wildcard {wildcards.cohort} -p page_type cohort -p analysis_version {analysis_version} 2> {log}
        """


rule process_headers_alert:
    input:
        nb="workflow/notebooks/add-headers.ipynb",
        alert_nb=f"{site_dir}/notebooks/alert/{{alert}}.ipynb",
        kernel=".kernel.set",
    output:
        nb=f"{site_dir}/notebooks/add_headers/{{alert}}.ipynb",
        alert_nb=f"{site_dir}/docs/alert/{{alert}}.ipynb",
    log:
        "logs/add_headers/alert-{alert}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p input_nb {input.alert_nb} -p output_nb {output.alert_nb} -p wildcard {wildcards.alert} -p page_type alert -p analysis_version {analysis_version} 2> {log}
        """

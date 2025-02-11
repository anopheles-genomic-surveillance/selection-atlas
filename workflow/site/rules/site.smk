def get_selection_atlas_site_files(wildcards):
    """Construct a list of all files required to compile the Jupyter book site."""

    # Read in cohorts dataframe.
    df = gpd.read_file(f"{analysis_dir}/final_cohorts.geojson")

    # Create a list of all required files.
    site_files = expand(
        [
            f"{site_dir}/docs/_config.yml",
            f"{site_dir}/docs/_toc.yml",
            f"{site_dir}/docs/home-page.ipynb",
            f"{site_dir}/docs/alerts.ipynb",
            f"{site_dir}/docs/country/{{country}}.ipynb",
            f"{site_dir}/docs/contig/ag-{{contig}}.ipynb",
            f"{site_dir}/docs/cohort/{{cohort}}.ipynb",
            f"{site_dir}/docs/alert/SA-AG-{{alert}}.ipynb",
        ],
        country=df["country_alpha2"],
        contig=contigs,
        cohort=df["cohort_id"].unique(),
        alert=config["alerts"],
    )

    return site_files


def get_h12_signal_detection_csvs(wildcards):

    # Read in cohorts.
    df = pd.read_csv(f"{analysis_dir}/final_cohorts.csv")

    # Create a list of file paths.
    paths = expand(
        "{analysis_dir}/h12-signal-detection/{cohort}_{contig}.csv",
        cohort=df["cohort_id"],
        contig=contigs,
        analysis_dir=analysis_dir,
    )
    return paths


rule compile_site:
    input:
        get_selection_atlas_site_files,
        config=configpath,
    output:
        directory(f"{site_dir}/docs/_build"),
    log:
        "logs/compile_site.log",
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
        f"workflow/docs/_config.yml",
        f"workflow/docs/alerts.ipynb",
        f"workflow/docs/favicon.ico",
    shell:
        f"""
        mkdir -pv {site_dir}/docs/
        cp -rv workflow/docs/* {site_dir}/docs/
        """


rule generate_toc:
    input:
        site_utils=f"workflow/notebooks/site-utils.py",
        nb=f"workflow/notebooks/generate-toc.ipynb",
        cohorts_geojson=f"{analysis_dir}/final_cohorts.geojson",
        config=configpath,
        kernel="results/kernel.set",
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
        site_utils=f"workflow/notebooks/site-utils.py",
        nb=f"workflow/notebooks/home-page.ipynb",
        config=configpath,
        cohorts_geojson=f"{analysis_dir}/final_cohorts.geojson",
        kernel="results/kernel.set",
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
        site_utils=f"workflow/notebooks/site-utils.py",
        nb=f"workflow/notebooks/country-page.ipynb",
        config=configpath,
        cohorts_geojson=f"{analysis_dir}/final_cohorts.geojson",
        kernel="results/kernel.set",
    output:
        nb=f"{site_dir}/notebooks/country/{{country}}.ipynb",
    log:
        "logs/country_pages/{country}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p country {wildcards.country} -f {input.config} 2> {log}
        """


rule contig_pages:
    input:
        site_utils=f"workflow/notebooks/site-utils.py",
        nb=f"workflow/notebooks/contig-page.ipynb",
        config=configpath,
        cohorts_geojson=f"{analysis_dir}/final_cohorts.geojson",
        signals=get_h12_signal_detection_csvs,
        kernel="results/kernel.set",
    output:
        nb=f"{site_dir}/notebooks/contig/ag-{{contig}}.ipynb",
    log:
        "logs/contig_pages/{contig}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p contig {wildcards.contig} -f {input.config} 2> {log}
        """


rule cohort_pages:
    input:
        site_utils=f"workflow/notebooks/site-utils.py",
        nb=f"workflow/notebooks/cohort-page.ipynb",
        cohorts_geojson=f"{analysis_dir}/final_cohorts.geojson",
        output_h12=f"{analysis_dir}/notebooks/h12-gwss-{{cohort}}.ipynb",
        output_g123=f"{analysis_dir}/notebooks/g123-gwss-{{cohort}}.ipynb",
        output_ihs=f"{analysis_dir}/notebooks/ihs-gwss-{{cohort}}.ipynb",
        config=configpath,
        signals=expand(
            "{analysis_dir}/h12-signal-detection/{{cohort}}_{contig}.csv",
            contig=contigs,
            analysis_dir=analysis_dir,
        ),
        kernel="results/kernel.set",
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
        site_utils=f"workflow/notebooks/site-utils.py",
        nb=f"workflow/notebooks/alert-page.ipynb",
        cohorts_geojson=f"{analysis_dir}/final_cohorts.geojson",
        config=configpath,
        alert_config=f"workflow/alerts/{{alert}}.yaml",
        signals=get_h12_signal_detection_csvs,
        kernel="results/kernel.set",
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
        kernel="results/kernel.set",
    output:
        nb=f"{site_dir}/notebooks/add_headers/home-page.ipynb",
        homepage_nb=f"{site_dir}/docs/home-page.ipynb",
    log:
        "logs/add_headers/home-page.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p input_nb {input.homepage_nb} -p output_nb {output.homepage_nb} -p page_type homepage -p analysis_version {analysis_version} 2> {log}
        """


rule process_headers_contig:
    input:
        nb="workflow/notebooks/add-headers.ipynb",
        contig_nb=f"{site_dir}/notebooks/contig/ag-{{contig}}.ipynb",
        kernel="results/kernel.set",
    output:
        nb=f"{site_dir}/notebooks/add_headers/{{contig}}.ipynb",
        contig_nb=f"{site_dir}/docs/contig/ag-{{contig}}.ipynb",
    log:
        "logs/add_headers/contig-{contig}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p input_nb {input.contig_nb} -p output_nb {output.contig_nb} -p wildcard {wildcards.contig} -p page_type contig -p analysis_version {analysis_version} 2> {log}
        """


rule process_headers_country:
    input:
        nb="workflow/notebooks/add-headers.ipynb",
        country_nb=f"{site_dir}/notebooks/country/{{country}}.ipynb",
        kernel="results/kernel.set",
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
        kernel="results/kernel.set",
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
        kernel="results/kernel.set",
    output:
        nb=f"{site_dir}/notebooks/add_headers/{{alert}}.ipynb",
        alert_nb=f"{site_dir}/docs/alert/{{alert}}.ipynb",
    log:
        "logs/add_headers/alert-{alert}.log",
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p input_nb {input.alert_nb} -p output_nb {output.alert_nb} -p wildcard {wildcards.alert} -p page_type alert -p analysis_version {analysis_version} 2> {log}
        """

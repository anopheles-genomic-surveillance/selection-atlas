rule build_site:
    input:
        "docs/_config.yml",
        "docs/_toc.yml",
        get_selection_atlas_site_pages,
        config = configpath,
    output:
        directory("docs/_build")
    log:    
        "logs/build-jupyter-book.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        jupyter-book build docs
        ln -sf docs/_build/html/index.html selection-atlas.html
        """

rule generate_toc:
    input:
        nb = f"{workflow.basedir}/notebooks/generate-toc.ipynb",
        cohorts_geojson = rules.geolocate_cohorts.output.cohorts_geojson,
        config = configpath,
    output:
        nb = "build/notebooks/generate-toc.ipynb",
        toc = "docs/_toc.yml",
    log:
        "logs/generate_toc.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -f {input.config} 2> {log}
        """

rule home_page:
    input:
        nb = f"{workflow.basedir}/notebooks/home-page.ipynb",
        config = configpath,
        cohorts_geojson = rules.geolocate_cohorts.output.cohorts_geojson,
    output:
        nb = "docs/home-page.ipynb"
    log:
        "logs/home_page.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas 2> {log}
        """

rule country_pages:
    input:
        nb = f"{workflow.basedir}/notebooks/country-page.ipynb",
        config = configpath,
        cohorts_geojson = rules.geolocate_cohorts.output.cohorts_geojson,
    output:
        nb = "build/notebooks/country/{country}.ipynb"
    log:
        "logs/country_pages/{country}.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p country {wildcards.country} 2> {log}
        """

rule chromosome_pages:
    input:
        nb = f"{workflow.basedir}/notebooks/chromosome-page.ipynb",
        config = configpath,
        cohorts_geojson = rules.geolocate_cohorts.output.cohorts_geojson,
        signals = get_h12_signal_detection_csvs,
    output:
        nb = "build/notebooks/genome/ag-{chrom}.ipynb"
    log:
        "logs/chromosome_pages/{chrom}.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p contig {wildcards.chrom} 2> {log}
        """

rule cohort_pages:
    input:
        nb = f"{workflow.basedir}/notebooks/cohort-page.ipynb",
        cohorts_geojson = rules.geolocate_cohorts.output.cohorts_geojson,
        output_h12="build/notebooks/h12-gwss-{cohort}.ipynb",
        config = configpath,
        #output_ihs="build/notebooks/ihs-gwss-{cohort}.ipynb",
        signals = expand("build/h12-signal-detection/{{cohort}}_{contig}.csv", contig=chromosomes),
    output:
        nb = "build/notebooks/cohort/{cohort}.ipynb",
    log:
        "logs/cohort_pages/{cohort}.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p cohort_id {wildcards.cohort} -f {input.config} 2> {log}
        """

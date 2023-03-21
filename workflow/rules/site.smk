rule geolocate_cohorts:
    input:
        nb = f"{workflow.basedir}/notebooks/geolocate-cohorts.ipynb",
        final_cohorts = lambda wildcards: checkpoints.final_cohorts.get().output[1],
        kernel= "build/.kernel.set",
    output:
        nb = "build/notebooks/geolocate-cohorts.ipynb",
        cohorts_geojson = "build/final_cohorts.geojson",
    log:
        "logs/geolocate_cohorts.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas 2> {log}
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
        cohorts_geojson = rules.geolocate_cohorts.output.cohorts_geojson,
    output:
        nb = "docs/notebooks/home-page.ipynb"
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
        cohorts_geojson = rules.geolocate_cohorts.output.cohorts_geojson,
    output:
        nb = "docs/notebooks/country-page-{country}.ipynb"
    log:
        "logs/country_page_{country}.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p country {wildcards.country} 2> {log}
        """

rule chromosome_pages:
    input:
        nb = f"{workflow.basedir}/notebooks/chromosome-page.ipynb",
        cohorts_geojson = rules.geolocate_cohorts.output.cohorts_geojson,
    output:
        nb = "docs/notebooks/chromosome-page-{chrom}.ipynb"
    log:
        "logs/chromosome_page_{chrom}.log"
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
        #output_ihs="build/notebooks/ihs-gwss-{cohort}.ipynb",
        signals = expand("build/h12-signal-detection/{{cohort}}_{contig}.csv", contig=chromosomes),
    output:
        nb = "docs/notebooks/cohort-page-{cohort}.ipynb"
    log:
        "logs/cohort_page_{cohort}.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p cohort_id {wildcards.cohort} 2> {log}
        """

rule build_site:
    input:
        "docs/_toc.yml",
        "docs/_config.yml",
        "docs/notebooks/home-page.ipynb",
        get_cohort_page_notebooks,
        get_country_page_notebooks,
        expand("docs/notebooks/chromosome-page-{chrom}.ipynb", chrom=chromosomes),
    output:
        directory("docs/_build")
    log:    
        "logs/build-jupyter-book.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        jupyter-book build docs
        """
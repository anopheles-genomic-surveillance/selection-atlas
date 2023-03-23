

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
        papermill {input.nb} {output.nb} -f {input.config} 2> {log}
        """

rule home_page:
    input:
        nb = f"{workflow.basedir}/notebooks/home-page.ipynb",
        cohorts_geojson = rules.geolocate_cohorts.output.cohorts_geojson,
    output:
        nb = "docs/home-page.ipynb"
    log:
        "logs/home_page.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} 2> {log}
        """

rule country_pages:
    input:
        nb = f"{workflow.basedir}/notebooks/country-page.ipynb",
        cohorts_geojson = rules.geolocate_cohorts.output.cohorts_geojson,
    output:
        nb = "build/notebooks/country/{country}.ipynb"
    log:
        "logs/country_pages/{country}.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} -p country {wildcards.country} 2> {log}
        """

rule chromosome_pages:
    input:
        nb = f"{workflow.basedir}/notebooks/chromosome-page.ipynb",
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
        papermill {input.nb} {output.nb} -p contig {wildcards.chrom} 2> {log}
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
        papermill {input.nb} {output.nb} -p cohort_id {wildcards.cohort} -f {input.config} 2> {log}
        """

rule process_headers_chrom:
    input:
        nb = "workflow/notebooks/add-headers.ipynb",
        chrom_nb = "build/notebooks/genome/ag-{contig}.ipynb",
    output:
        nb = "build/notebooks/add_headers/{contig}.ipynb",
        chrom_nb = "docs/genome/ag-{contig}.ipynb",
    log:
        "logs/add_headers/{contig}.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} -p input_nb {input.chrom_nb} -p output_nb {output.chrom_nb} -p wildcard {wildcards.contig} -p type chrom 2> {log}
        """

rule process_headers_country:
    input:
        nb = "workflow/notebooks/add-headers.ipynb",
        country_nb = "build/notebooks/country/{country}.ipynb"
    output:
        nb = "build/notebooks/add_headers/{country}.ipynb",
        country_nb = "docs/country/{country}.ipynb",        
    log:
        "logs/add_headers/{country}.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} -p input_nb {input.country_nb} -p output_nb {output.country_nb} -p wildcard {wildcards.country} -p type country 2> {log}
        """

    
rule process_headers_cohort:
    input:
        nb = "workflow/notebooks/add-headers.ipynb",
        cohort_nb = "build/notebooks/cohort/{cohort}.ipynb"
    output:
        nb = "build/notebooks/add_headers/{cohort}.ipynb",
        cohort_nb = "docs/cohort/{cohort}.ipynb",       
    log:
        "logs/add_headers/{cohort}.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} -p input_nb {input.cohort_nb} -p output_nb {output.cohort_nb} -p wildcard {wildcards.cohort} -p type cohort 2> {log}
        """

rule build_site:
    input:
        "docs/_config.yml",
        # "docs/_toc.yml",
        # "docs/home-page.ipynb",
        get_selection_atlas_site_pages,
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
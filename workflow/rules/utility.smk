rule process_headers_home:
    input:
        nb = "workflow/notebooks/add-headers.ipynb",
        homepage_nb = f"{build_dir}/notebooks/home-page.ipynb",
        kernel=".kernel.set"
    output:
        nb = f"{build_dir}/notebooks/add_headers/home-page.ipynb",
        homepage_nb = "docs/home-page.ipynb",       
    log:
        "logs/add_headers/home-page.log"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p input_nb {input.homepage_nb} -p output_nb {output.homepage_nb} -p page_type homepage -p analysis_version {analysis_version} 2> {log}
        """
        
rule process_headers_chrom:
    input:
        nb = "workflow/notebooks/add-headers.ipynb",
        chrom_nb = f"{build_dir}/notebooks/genome/ag-{{contig}}.ipynb",
        kernel=".kernel.set"
    output:
        nb = f"{build_dir}/notebooks/add_headers/{{contig}}.ipynb",
        chrom_nb = "docs/genome/ag-{contig}.ipynb",
    log:
        "logs/add_headers/{contig}.log"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p input_nb {input.chrom_nb} -p output_nb {output.chrom_nb} -p wildcard {wildcards.contig} -p page_type chrom -p analysis_version {analysis_version} 2> {log}
        """

rule process_headers_country:
    input:
        nb = "workflow/notebooks/add-headers.ipynb",
        country_nb = f"{build_dir}/notebooks/country/{{country}}.ipynb",
        kernel=".kernel.set"
    output:
        nb = f"{build_dir}/notebooks/add_headers/{{country}}.ipynb",
        country_nb = "docs/country/{country}.ipynb",        
    log:
        "logs/add_headers/{country}.log"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p input_nb {input.country_nb} -p output_nb {output.country_nb} -p wildcard {wildcards.country} -p page_type country -p analysis_version {analysis_version} 2> {log}
        """

    
rule process_headers_cohort:
    input:
        nb = "workflow/notebooks/add-headers.ipynb",
        cohort_nb = f"{build_dir}/notebooks/cohort/{{cohort}}.ipynb",
        kernel=".kernel.set"
    output:
        nb = f"{build_dir}/notebooks/add_headers/{{cohort}}.ipynb",
        cohort_nb = "docs/cohort/{cohort}.ipynb",       
    log:
        "logs/add_headers/{cohort}.log"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p input_nb {input.cohort_nb} -p output_nb {output.cohort_nb} -p wildcard {wildcards.cohort} -p page_type cohort -p analysis_version {analysis_version} 2> {log}
        """
        

rule set_kernel:
    input:
        f"{workflow.basedir}/../environment.yml"
    output:
        touch(".kernel.set")
    conda:
        f"{workflow.basedir}/../environment.yml"
    log:
        "logs/set_kernel.log"
    shell: 
        """
        python -m ipykernel install --user --name selection-atlas 2> {log}
        """

rule process_headers_chrom:
    input:
        nb = "workflow/notebooks/add-headers.ipynb",
        chrom_nb = "build/notebooks/genome/ag-{contig}.ipynb",
        kernel=".kernel.set"
    output:
        nb = "build/notebooks/add_headers/{contig}.ipynb",
        chrom_nb = "docs/genome/ag-{contig}.ipynb",
    log:
        "logs/add_headers/{contig}.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p input_nb {input.chrom_nb} -p output_nb {output.chrom_nb} -p wildcard {wildcards.contig} -p type chrom 2> {log}
        """

rule process_headers_country:
    input:
        nb = "workflow/notebooks/add-headers.ipynb",
        country_nb = "build/notebooks/country/{country}.ipynb",
        kernel=".kernel.set"
    output:
        nb = "build/notebooks/add_headers/{country}.ipynb",
        country_nb = "docs/country/{country}.ipynb",        
    log:
        "logs/add_headers/{country}.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p input_nb {input.country_nb} -p output_nb {output.country_nb} -p wildcard {wildcards.country} -p type country 2> {log}
        """

    
rule process_headers_cohort:
    input:
        nb = "workflow/notebooks/add-headers.ipynb",
        cohort_nb = "build/notebooks/cohort/{cohort}.ipynb",
        kernel=".kernel.set"
    output:
        nb = "build/notebooks/add_headers/{cohort}.ipynb",
        cohort_nb = "docs/cohort/{cohort}.ipynb",       
    log:
        "logs/add_headers/{cohort}.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas -p input_nb {input.cohort_nb} -p output_nb {output.cohort_nb} -p wildcard {wildcards.cohort} -p type cohort 2> {log}
        """
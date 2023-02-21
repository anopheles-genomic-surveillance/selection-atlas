
# rule generate_cohorts:
#     input:
#         "workflow/generate-cohorts.ipynb"
#     output:
#         "build/notebooks/generate-cohorts.ipynb",
#         "cohorts.tsv"
#     log:
#         "logs/generate_cohorts.log"
#     conda:
#         "../environment.yaml"
#     shell:
#         """
#         papermill {input.nb} {output.nb} -k selection-atlas 
#         """


rule generate_toc:
    input:
        "workflow/generate-toc.ipynb"
    output:
        "build/notebooks/generate-toc.ipynb",
        "docs/.toc.yaml"
    log:
        "logs/generate_toc.log"
    conda:
        "../environment.yaml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas 
        """

rule home_page:
    input:
        "workflow/home-page.ipynb"
    output:
        "build/notebooks/home-page.ipynb"
    log:
        "logs/home_page.log"
    conda:
        "../environment.yaml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas 
        """

rule country_pages:
    input:
        "workflow/country-page.ipynb"
    output:
        "build/notebooks/country-page-{country}.ipynb"
    log:
        "logs/country_page_{country}.log"
    conda:
        "../environment.yaml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas 
        """


rule chromosome_pages:
    input:
        "workflow/chromosome-page.ipynb"
    output:
        "build/notebooks/chromosome-page-{chrom}.ipynb"
    log:
        "logs/chromomsome_page_{chrom}.log"
    conda:
        "../environment.yaml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas 
        """


rule cohort_pages:
    input:
        "workflow/cohort-page.ipynb"
    output:
        "build/notebooks/cohort-page-{cohort}.ipynb"
    log:
        "logs/cohort_page_{cohort}.log"
    conda:
        "../environment.yaml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas 
        """
rule generate_toc:
    input:
        f"{workflow.basedir}/notebooks/generate-toc.ipynb",
        lambda wildcards: checkpoints.final_cohorts.get().output[1]
    output:
        "build/notebooks/generate-toc.ipynb",
        "docs/.toc.yaml"
    log:
        "logs/generate_toc.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas 
        """

rule home_page:
    input:
        f"{workflow.basedir}/notebooks/home-page.ipynb",
        lambda wildcards: checkpoints.final_cohorts.get().output[1]
    output:
        "docs/notebooks/home-page.ipynb"
    log:
        "logs/home_page.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas 
        """

rule country_pages:
    input:
        f"{workflow.basedir}/notebooks/country-page.ipynb",
        lambda wildcards: checkpoints.final_cohorts.get().output[1]
    output:
        "docs/notebooks/country-page-{country}.ipynb"
    log:
        "logs/country_page_{country}.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas 
        """


rule chromosome_pages:
    input:
        f"{workflow.basedir}/notebooks/chromosome-page.ipynb"
    output:
        "docs/notebooks/chromosome-page-{chrom}.ipynb"
    log:
        "logs/chromosome_page_{chrom}.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas 
        """


rule cohort_pages:
    input:
        f"{workflow.basedir}/notebooks/cohort-page.ipynb"
    output:
        "docs/notebooks/cohort-page-{cohort}.ipynb"
    log:
        "logs/cohort_page_{cohort}.log"
    conda:
        f"{workflow.basedir}/../environment.yml"
    shell:
        """
        papermill {input.nb} {output.nb} -k selection-atlas 
        """
# Malaria Vector Selection Atlas

This repo contains the source code for the [Malaria Vector Selection Atlas](https://anopheles-genomic-surveillance.github.io/selection-atlas/).

This README contains information for developers and contributors to the selection atlas.

## Development docs

The following documents capture early design work and implementation planning. These are mostly redundant now as the proposed work has been completed, and further work will be discussed via GitHub issues, but these may still be of some historical interest:

-   [Implementation plan](https://docs.google.com/document/d/1VvVZqIQWP8a2zH_CqTgKOp7_KotiJX8bcQ-RWfxiEj8/edit?usp=sharing)
-   [UI design](https://www.figma.com/file/k8lS8xUvYmPopMv1MpyYO0/Selection-atlas?node-id=3487%3A6008&t=bUqtIieBnHcFTzk3-1)
-   [Workflow design](https://miro.com/app/board/uXjVPlYc-lM=/?share_link_id=382195427430)

## Conda environment management

In order to develop or contribute to the selection atlas, you will need to create a conda environment on the system where you are working.

Instructions below assume you have a recent version of conda and mamba installed. Alternatively you could use micromamba instead of conda and mamba.

The file `environment.yml` has a fully pinned conda environment specification. This is the environment to use for development work and running workflows.

To create and activate an environment on your own computer:

```
mamba env create --file environment.yml
conda activate selection-atlas
```

To create and activate an environment on datalab-bespin:

```
mamba env create --prefix=${HOME}/envs/selection-atlas --file environment.yml
conda activate ${HOME}/envs/selection-atlas
```

If you are developing and need to add or upgrade a package, edit `requirements.yml`. **Do not edit `environment.yml`**. Then re-solve the environment to regenerate `environment.yml` as follows:

```
mamba env create --file requirements.yml
conda env export -f environment.yml -n selection-atlas-requirements --override-channels --channel conda-forge --channel bioconda
sed -i "s/selection-atlas-requirements/selection-atlas/" environment.yml
```

## Pre-commit hooks

There are several pre-commit hooks configured to automatically lint and format source code files, including Python files, Jupyter notebooks and Snakemake files. These will be automatically run before any code is committed if you install pre-commit hooks:

```
pre-commit install
```

## Authenticating with Google Cloud

In order to run workflows, you will need to be authenticated with Google Cloud. With the selection-atlas environment activated, run the following commands and follow the instructions given:

```
gcloud auth login
gcloud auth application-default login
```

## Running the analysis workflow

The analysis workflow will run genome-wide selections over all cohorts found within the sample sets given in the workflow configuration. See the file `workflow/config.yaml` for workflow configuration.

Please note that this workflow will generally require a lot of computation and data access, and so needs to be run on a machine within Google Cloud in the us-central1 region. This can be achieved by using datalab-bespin or by using a Vertex AI Workbench VM.

During development, you may want to run the workflow without any parallelisation:

```
snakemake -c1 --snakefile workflow/analysis.smk
```

To run the workflow fully, you can try running with parallelisation. Note this will need to be on a machine with sufficient cores and memory. E.g.:

```
snakemake -c4 --snakefile workflow/analysis.smk
```

The outputs of the analysis workflow will be stored in the "build" folder, under a sub-folder named according to the "analysis_version" parameter given in the workflow configuration file.

Remember that if you make any significant changes to the configuration and rerun the workflow, change the "analysis_version" parameter in the workflow configuration file.

## Saving/restoring outputs of a successful analysis workflow run

After a successful run of the analysis workflow, copy the workflow outputs to GCS. This will allow you or other developers to continue working to improve the site based on these outputs, without having to do a complete analysis workflow run themselves.

With the selection-atlas environment activated, copy workflow outputs to GCS:

```
gcloud storage rsync -r -u build/ gs://vo_selection_atlas_dev_us_central1/build/
```

To restore outputs from a previous workflow run to your local filesystem:

```
gcloud storage rsync -r -u gs://vo_selection_atlas_dev_us_central1/build/ build/
find build -type f -exec touch {} +
```

## Running the site workflow

The site workflow will use the outputs from the analysis-workflow and build all of the content for the selection atlas website. To run this workflow:

```
MGEN_SHOW_PROGRESS=0 snakemake -c1 --snakefile workflow/site.smk
```

You can run this workflow on a smaller computer as it should not need to perform any heavy computations.

It currently does need to access some data in GCS, however, and so is also best run from a VM inside GCP.

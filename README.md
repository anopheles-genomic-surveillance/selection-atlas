# selection-atlas

Development docs:

-   [Implementation plan](https://docs.google.com/document/d/1VvVZqIQWP8a2zH_CqTgKOp7_KotiJX8bcQ-RWfxiEj8/edit?usp=sharing)
-   [UI design](https://www.figma.com/file/k8lS8xUvYmPopMv1MpyYO0/Selection-atlas?node-id=3487%3A6008&t=bUqtIieBnHcFTzk3-1)
-   [Workflow design](https://miro.com/app/board/uXjVPlYc-lM=/?share_link_id=382195427430)

## Conda environment management

Assuming you have a recent version of mamba installed.

The file `requirements.yml` has the dependencies required to build the site. To ensure reproducibility we currently also maintain the file `environment.yml` which contains an export of the solved environment.

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

If you need to add or upgrade a package, edit `requirements.yml`. **Do not edit `environment.yml`**.

To upgrade `environment.yml`:

```
mamba env create --file requirements.yml
mamba env export -f environment.yml -n selection-atlas-requirements --override-channels --channel conda-forge --channel bioconda
sed -i "s/selection-atlas-requirements/selection-atlas/" environment.yml
```

## Authenticating with Google Cloud

With the selection-atlas environment activated:

```
gcloud auth login
gcloud auth application-default login
```


## Running the analysis workflow

See the file `workflow/config.yaml` for workflow configuration.

If running on your local system with GCS caching enabled, you'll need to run the build without any parallelisation:

```
snakemake -c1 --snakefile workflow/Snakefile-analysis
```

If running on Google Cloud and GCS caching is disabled, you can try running with parallelisation, e.g.:

```
snakemake -c4 --snakefile workflow/Snakefile-analysis
```


## Saving/restoring a successful workflow run

After a successful workflow run, copy the workflow outputs to GCS. This will allow you or other developers to continue working to improve the site based on these outputs, without having to do a complete workflow run themselves. 

With the selection-atlas environment activated, copy workflow outputs to GCS:

```
gsutil -m rsync -r build/ gs://vo_selection_atlas_dev_us_central1/build/2024-08-21/
```

In the above command, "2024-08-21" is a build identifier. If you make any significant changes and rerun the workflow, use a new build identifier.

To restore outputs from a previous workflow run to your local filesystem:

```
rm -r build/*
gsutil -m rsync -r gs://vo_selection_atlas_dev_us_central1/build/2024-08-21/ build/
find build -type f -exec touch {} +
find build/notebooks -type f -exec touch {} +
find build/notebooks/cohort -type f -exec touch {} +

```

## Running the site-build workflow

See the file `workflow/config.yaml` for workflow configuration.

```
snakemake -c1 --snakefile workflow/Snakefile-site-build
```
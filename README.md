# selection-atlas

Here be dragons.

Development docs:

-   [Implementation plan](https://docs.google.com/document/d/1VvVZqIQWP8a2zH_CqTgKOp7_KotiJX8bcQ-RWfxiEj8/edit?usp=sharing)
-   [UI design](https://www.figma.com/file/k8lS8xUvYmPopMv1MpyYO0/Selection-atlas?node-id=3487%3A6008&t=bUqtIieBnHcFTzk3-1)
-   [Workflow design](https://miro.com/app/board/uXjVPlYc-lM=/?share_link_id=382195427430)

## Conda environment management

Assuming you have a recent version of mamba installed.

The file `requirements.yml` has the dependencies required to build the site. To ensure reproducibility we currently also maintain the file `environment.yml` which contains an export of the solved environment.

If you need to add or upgrade a package, edit `requirements.yml`. Do not edit `environment.yml`.

To upgrade `environment.yml`:

```
mamba env create --force --file requirements.yml
mamba env export -f environment.yml -n selection-atlas-requirements --override-channels --channel conda-forge --channel bioconda
sed -i "s/selection-atlas-requirements/selection-atlas/" environment.yml
```

To install and use `environment.yml`:

```
mamba env create --force --file environment.yml
mamba activate selection-atlas
```

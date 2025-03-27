#!/usr/bin/env bash

set -xeuo pipefail

# Turn off progress output.
export MGEN_SHOW_PROGRESS=0

# Run the agam site workflow.
snakemake \
    --snakefile workflow/site/Snakefile \
    --configfile config/agam.yaml \
    --show-failed-logs \
    --rerun-incomplete

# Run the afun site workflow.
snakemake \
    --snakefile workflow/site/Snakefile \
    --configfile config/afun.yaml \
    --show-failed-logs \
    --rerun-incomplete

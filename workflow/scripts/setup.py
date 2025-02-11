# Common setup for both workflows. Designed so that this file can be
# included into the workflows and also run from within a notebook.

import os
import warnings
import functools  # noqa
from pyprojroot import here
import dask
import malariagen_data
import yaml  # noqa
import numpy as np  # noqa
import pandas as pd  # noqa
import geopandas as gpd  # noqa
import iso3166  # noqa

# Locate repo root dir.
root = here()

# Configure dask.
dask.config.set(scheduler=dask_scheduler)

# Configure warnings.
warnings.filterwarnings("ignore")

# Assume these variables come from the workflow configuration and have
# already been set somehow.
assert isinstance(analysis_version, str)
assert isinstance(cohorts_analysis, str)
assert isinstance(dask_scheduler, str)
assert isinstance(contigs, list)

# Path to kernel set flag file.
kernel_set_file = root / "results/kernel.set"

# Path to main environment file.
environment_file = root / "workflow/envs/selection-atlas.yaml"

# Paths to analysis workflow results.
results_dir = root / "results" / analysis_version
gwss_results_dir = results_dir / "gwss"
os.makedirs(gwss_results_dir, exist_ok=True)
cohorts_file = gwss_results_dir / "cohorts.csv"
final_cohorts_file = gwss_results_dir / "final_cohorts.csv"
final_cohorts_geojson_file = gwss_results_dir / "final_cohorts.geojson"
h12_calibration_dir = gwss_results_dir / "h12-calibration"
os.makedirs(h12_calibration_dir, exist_ok=True)
h12_calibration_files = h12_calibration_dir / "{cohort}.yaml"
h12_signal_dir = gwss_results_dir / "h12-signal-detection"
os.makedirs(h12_signal_dir, exist_ok=True)
h12_signal_files = h12_signal_dir / "{cohort}_{contig}.csv"
g123_calibration_dir = gwss_results_dir / "g123-calibration"
os.makedirs(g123_calibration_dir, exist_ok=True)
g123_calibration_files = g123_calibration_dir / "{cohort}.yaml"

# Paths to site workflow results.
site_results_dir = results_dir / "site"
os.makedirs(site_results_dir, exist_ok=True)
jb_source_dir = site_results_dir / "docs"
jb_build_dir = jb_source_dir / "_build"

# Setup access to malariagen data.
malariagen_data_cache_path = results_dir / "malariagen_data_cache"
ag3 = malariagen_data.Ag3(
    # Pin the version of the cohorts analysis for reproducibility.
    cohorts_analysis=cohorts_analysis,
    results_cache=malariagen_data_cache_path.as_posix(),
)

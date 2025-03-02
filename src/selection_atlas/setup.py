# Common setup for both workflows. Designed so that this file can be
# imported into Snakemake workflows and also imported into a notebook.

import os
import warnings
from pyprojroot import here
import dask
import malariagen_data


class AtlasSetup:
    def __init__(
        self,
        atlas_id: str,
        analysis_version: str,
        cohorts_analysis: str,
        dask_scheduler: str,
        contigs: list,
    ):
        # Given configuration parameters.
        self.atlas_id = atlas_id
        self.analysis_version = analysis_version
        self.cohorts_analysis = cohorts_analysis
        self.dask_scheduler = dask_scheduler
        self.contigs = tuple(contigs)

        # Locate repo root dir.
        self.here = here()

        # Configure dask.
        dask.config.set(scheduler=dask_scheduler)

        # Configure warnings.
        warnings.filterwarnings("ignore")

        # Path to main environment file.
        self.environment_file = self.here / "workflow/common/envs/selection-atlas.yaml"

        # Path to alerts.
        self.alerts_dir = self.here / "alerts"

        # Path to all workflow results.
        self.output_dir = self.here / "results"
        self.analysis_dir = self.output_dir / atlas_id / analysis_version
        os.makedirs(self.analysis_dir, exist_ok=True)

        # Path to kernel set flag file.
        self.kernel_set_file = self.analysis_dir / "kernel.set"

        # Paths to gwss workflow results.
        self.gwss_results_dir = self.analysis_dir / "gwss"
        os.makedirs(self.gwss_results_dir, exist_ok=True)

        # Cohorts files.
        self.cohorts_file = self.gwss_results_dir / "cohorts.csv"
        self.final_cohorts_file = self.gwss_results_dir / "final_cohorts.csv"
        self.final_cohorts_geojson_file = (
            self.gwss_results_dir / "final_cohorts.geojson"
        )

        # H12 files.
        self.h12_calibration_dir = self.gwss_results_dir / "h12-calibration"
        os.makedirs(self.h12_calibration_dir, exist_ok=True)
        self.h12_calibration_files = self.h12_calibration_dir / "{cohort}.yaml"
        self.h12_signal_dir = self.gwss_results_dir / "h12-signal-detection"
        os.makedirs(self.h12_signal_dir, exist_ok=True)
        self.h12_signal_files = self.h12_signal_dir / "{cohort}_{contig}.csv"

        # G123 files.
        self.g123_calibration_dir = self.gwss_results_dir / "g123-calibration"
        os.makedirs(self.g123_calibration_dir, exist_ok=True)
        self.g123_calibration_files = self.g123_calibration_dir / "{cohort}.yaml"

        # Paths to site workflow results.
        self.site_results_dir = self.analysis_dir / "site"
        os.makedirs(self.site_results_dir, exist_ok=True)
        self.jb_source_dir = self.site_results_dir / "docs"
        self.jb_build_dir = self.jb_source_dir / "_build"

        # Setup access to malariagen data.
        self.malariagen_data_cache_path = self.output_dir / "malariagen_data_cache"

        if atlas_id == "agam":
            self.malariagen_api = malariagen_data.Ag3(
                # Pin the version of the cohorts analysis for reproducibility.
                cohorts_analysis=cohorts_analysis,
                results_cache=self.malariagen_data_cache_path.as_posix(),
                check_location=False,
            )

        elif atlas_id == "afun":
            self.malariagen_api = malariagen_data.Af1(
                # Pin the version of the cohorts analysis for reproducibility.
                cohorts_analysis=cohorts_analysis,
                results_cache=self.malariagen_data_cache_path.as_posix(),
                check_location=False,
            )

        else:
            raise RuntimeError(f"Unexpected atlas_id: {atlas_id}.")

    def __hash__(self):
        return hash(
            self.atlas_id,
            self.analysis_version,
            self.cohorts_analysis,
            self.contigs,
        )

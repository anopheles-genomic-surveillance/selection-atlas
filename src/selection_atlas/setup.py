# Common setup for both workflows. Designed so that this file can be
# imported into Snakemake workflows and also imported into a notebook.

import os
import warnings
from pyprojroot import here
import dask
import yaml
import malariagen_data
import tqdm.std


class AtlasSetup:
    def __init__(
        self,
        config_file: str,
    ):
        self.config_file = config_file
        with open(self.config_file, mode="r") as f:
            self.config = yaml.safe_load(f)

        # Store configuration parameters.
        self.atlas_id = self.config["atlas_id"]
        self.atlas_title = self.config["atlas_title"]
        self.analysis_version = self.config["analysis_version"]
        self.cohorts_analysis = self.config["cohorts_analysis"]
        self.dask_scheduler = self.config["dask_scheduler"]
        self.contigs = self.config["contigs"]
        self.sample_sets = self.config["sample_sets"]
        self.sample_query = self.config["sample_query"]
        self.min_cohort_size = self.config["min_cohort_size"]
        self.max_cohort_size = self.config["max_cohort_size"]
        self.h12_calibration_contig = self.config["h12_calibration_contig"]
        self.h12_calibration_window_sizes = self.config["h12_calibration_window_sizes"]
        self.h12_calibration_threshold = self.config["h12_calibration_threshold"]
        self.h12_signal_detection_min_delta_aic = self.config[
            "h12_signal_detection_min_delta_aic"
        ]
        self.h12_signal_detection_min_stat_max = self.config[
            "h12_signal_detection_min_stat_max"
        ]
        self.h12_signal_detection_gflanks = self.config["h12_signal_detection_gflanks"]
        self.g123_calibration_contig = self.config["g123_calibration_contig"]
        self.g123_calibration_window_sizes = self.config[
            "g123_calibration_window_sizes"
        ]
        self.g123_calibration_threshold = self.config["g123_calibration_threshold"]
        self.ihs_window_size = self.config["ihs_window_size"]
        self.taxa = self.config["taxa"]
        self.taxon_phasing_analysis = self.config["taxon_phasing_analysis"]
        self.taxon_site_mask = self.config["taxon_site_mask"]
        self.alerts = self.config["alerts"]

        # Locate repo root dir.
        self.here = here()

        # Configure dask.
        dask.config.set(scheduler=self.dask_scheduler)

        # Configure warnings.
        warnings.filterwarnings("ignore")

        # Path to main environment file.
        self.environment_file = self.here / "workflow/common/envs/selection-atlas.yaml"

        # Path to alerts.
        self.alerts_dir = self.here / "alerts"

        # Paths to Python source files.
        self.src_dir = self.here / "src" / "selection_atlas"
        self.gwss_src_files = [
            self.src_dir / "setup.py",
            self.src_dir / "peak_utils.py",
        ]
        self.site_src_files = [
            self.src_dir / "setup.py",
            self.src_dir / "page_utils.py",
        ]

        # These files are completely static, no dynamically-generated content.
        self.static_site_files = [
            "alerts.ipynb",
            "methods.md",
            "faq.md",
            "glossary.md",
            f"logo-{self.atlas_id}.png",
            "favicon.ico",
            "_static/custom.css",
        ]

        # Path to all workflow results.
        self.results_dir = self.here / "results"
        self.analysis_dir = self.results_dir / self.atlas_id / self.analysis_version
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

        # Window size calibration files.
        self.calibration_dir = self.gwss_results_dir / "calibration"
        os.makedirs(self.calibration_dir, exist_ok=True)
        self.calibration_files = self.calibration_dir / "{cohort}.yaml"

        # Signal detection files.
        self.h12_signal_dir = self.gwss_results_dir / "h12-signal-detection"
        os.makedirs(self.h12_signal_dir, exist_ok=True)
        self.h12_signal_files = self.h12_signal_dir / "{cohort}_{contig}.csv"

        # Paths to site workflow results.
        self.site_results_dir = self.analysis_dir / "site"
        os.makedirs(self.site_results_dir, exist_ok=True)

        # Paths to the Jupyter Book files.
        self.jb_source_dir = self.site_results_dir / "docs"
        os.makedirs(self.jb_source_dir, exist_ok=True)
        self.jb_build_dir = self.jb_source_dir / "_build"

        # Setup access to malariagen data.
        self.malariagen_data_cache_path = self.results_dir / "malariagen_data_cache"
        self._malariagen_api = None

    @property
    def malariagen_api(self):
        # Lazily initialise MalariaGEN API.
        if self._malariagen_api is None:
            if self.atlas_id == "agam":
                self._malariagen_api = malariagen_data.Ag3(
                    # Pin the version of the cohorts analysis for reproducibility.
                    cohorts_analysis=self.cohorts_analysis,
                    results_cache=self.malariagen_data_cache_path.as_posix(),
                    check_location=False,
                    tqdm_class=tqdm.std.tqdm,
                )
            elif self.atlas_id == "afun":
                self._malariagen_api = malariagen_data.Af1(
                    # Pin the version of the cohorts analysis for reproducibility.
                    cohorts_analysis=self.cohorts_analysis,
                    results_cache=self.malariagen_data_cache_path.as_posix(),
                    check_location=False,
                    tqdm_class=tqdm.std.tqdm,
                )
            else:
                raise RuntimeError(f"Unexpected atlas_id: {atlas_id}.")
        return self._malariagen_api

    def sample_metadata(self):
        return self.malariagen_api.sample_metadata(
            sample_sets=self.sample_sets, sample_query=self.sample_query
        )

    def __hash__(self):
        return hash(self.config_file)


rule set_kernel:
    input:
        f"workflow/envs/selection-atlas.yaml",
    output:
        touch("results/kernel.set"),
    log:
        "logs/set_kernel.log",
    shell:
        """
        python -m ipykernel install --user --name selection-atlas 2> {log}
        """


def get_h12_calibration_yamls(wildcards):
    df = pd.read_csv(checkpoints.setup_cohorts.get().output[1])
    paths = f"{analysis_dir}/h12-calibration/" + df["cohort_id"] + ".yaml"
    return paths


def get_h12_signal_detection_csvs(wildcards):
    df = pd.read_csv(checkpoints.final_cohorts.get().output[1])
    paths = expand(
        "{analysis_dir}/h12-signal-detection/{cohort}_{contig}.csv",
        cohort=df["cohort_id"],
        contig=chromosomes,
        analysis_dir=analysis_dir,
    )
    return paths


def get_selection_atlas_outputs(wildcards):
    # retrieve output file of final cohorts checkpoint
    df = gpd.read_file(checkpoints.geolocate_cohorts.get().output.cohorts_geojson)

    # define paths to output files
    h12_cal_paths = f"{analysis_dir}/h12-calibration/" + df["cohort_id"] + ".yaml"
    h12_cal_notebook_paths = (
        f"{analysis_dir}/notebooks/h12-calibration-" + df["cohort_id"] + ".ipynb"
    )
    h12_gwss_paths = f"{analysis_dir}/notebooks/h12-gwss-" + df["cohort_id"] + ".ipynb"
    h12_signal_paths = expand(
        "{analysis_dir}/h12-signal-detection/{cohort}_{contig}.csv",
        cohort=df["cohort_id"],
        contig=chromosomes,
        analysis_dir=analysis_dir,
    )

    # define paths to output files
    g123_cal_paths = f"{analysis_dir}/g123-calibration/" + df["cohort_id"] + ".yaml"
    g123_cal_notebook_paths = (
        f"{analysis_dir}/notebooks/g123-calibration-" + df["cohort_id"] + ".ipynb"
    )
    g123_gwss_paths = (
        f"{analysis_dir}/notebooks/g123-gwss-" + df["cohort_id"] + ".ipynb"
    )

    ihs_gwss_paths = f"{analysis_dir}/notebooks/ihs-gwss-" + df["cohort_id"] + ".ipynb"

    # add output files to list
    wanted_outputs = []
    wanted_outputs.extend(h12_cal_paths)
    wanted_outputs.extend(h12_cal_notebook_paths)
    wanted_outputs.extend(h12_gwss_paths)
    wanted_outputs.extend(h12_signal_paths)
    wanted_outputs.extend(g123_cal_paths)
    wanted_outputs.extend(g123_cal_notebook_paths)
    wanted_outputs.extend(g123_gwss_paths)
    wanted_outputs.extend(ihs_gwss_paths)

    return wanted_outputs


def get_cohort_page_notebooks(wildcards):
    df = gpd.read_file(checkpoints.geolocate_cohorts.get().output.cohorts_geojson)

    outputs = expand("docs/cohort/{cohort}.ipynb", cohort=df["cohort_id"].unique())

    return outputs


def get_country_page_notebooks(wildcards):
    df = gpd.read_file(checkpoints.geolocate_cohorts.get().output.cohorts_geojson)

    outputs = expand("docs/country/{country}.ipynb", country=df["country_alpha2"])
    return outputs

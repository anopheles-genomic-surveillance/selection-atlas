def get_h12_calibration_yamls(wildcards):
    df = pd.read_csv(checkpoints.setup_cohorts.get().output[1])
    paths = "build/h12-calibration/" + df['cohort_id'] + ".yaml"
    return paths

def get_h12_signal_detection_csvs(wildcards):
    df = pd.read_csv(checkpoints.final_cohorts.get().output[1])
    paths = expand("build/h12-signal-detection/{cohort}_{contig}.csv", cohort=df['cohort_id'], contig=chromosomes)
    return paths

def get_selection_atlas_outputs(wildcards):
    # retrieve output file of final cohorts checkpoint
    df = gpd.read_file(checkpoints.geolocate_cohorts.get().output.cohorts_geojson)

    # define paths to output files
    cal_paths = "build/h12-calibration/" + df['cohort_id'] + ".yaml"
    cal_notebook_paths = "build/notebooks/h12-calibration-" + df['cohort_id'] + ".ipynb"
    gwss_paths = "build/notebooks/h12-gwss-" + df['cohort_id'] + ".ipynb"
    signal_paths = expand("build/h12-signal-detection/{cohort}_{contig}.csv", cohort=df['cohort_id'], contig=chromosomes)

    # add output files to list
    wanted_outputs = []
    wanted_outputs.extend(cal_paths)
    wanted_outputs.extend(cal_notebook_paths)
    wanted_outputs.extend(gwss_paths)
    wanted_outputs.extend(signal_paths)
    
    return wanted_outputs


def get_selection_atlas_site_pages(wildcards):

    df = gpd.read_file(checkpoints.geolocate_cohorts.get().output.cohorts_geojson)

    wanted_outputs = []
    wanted_outputs.extend(["docs/_toc.yml"])
    wanted_outputs.extend(["docs/home-page.ipynb"])
    wanted_outputs.extend(
                expand("docs/country/{country}.ipynb", country=df['country_alpha2'])
        )

    wanted_outputs.extend(
                expand("docs/genome/ag-{chrom}.ipynb", chrom=chromosomes)
        )
    
    wanted_outputs.extend(
                expand("docs/cohort/{cohort}.ipynb", cohort=df['cohort_id'].unique())
    )
    return wanted_outputs 


def get_cohort_page_notebooks(wildcards):
    df = gpd.read_file(checkpoints.geolocate_cohorts.get().output.cohorts_geojson)
    
    outputs = expand(
        "docs/cohort/{cohort}.ipynb", 
        cohort=df['cohort_id'].unique()
        )

    return outputs


def get_country_page_notebooks(wildcards):
    df = gpd.read_file(checkpoints.geolocate_cohorts.get().output.cohorts_geojson)

    outputs = expand(
        "docs/country/{country}.ipynb", 
        country=df['country_alpha2']
    )
    return outputs
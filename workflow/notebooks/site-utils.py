# Utility variables and functions used in the site page notebooks.
# We expect this script to be executed via a %run magic command
# from within a Jupyter notebook.

# Expect that these variables will have been assigned prior to
# importing this module.
assert dask_scheduler is not None
assert analysis_version is not None

# Standad library imports.
from textwrap import dedent
import warnings

# Third party library imports.
from IPython.display import Markdown, HTML
from ipyleaflet import Map, Marker, basemaps, AwesomeIcon
from ipywidgets import HTML
import malariagen_data
import numpy as np
import pandas as pd
from pyprojroot import here
import yaml
import dask
import geopandas as gpd
import bokeh.layouts as bklay
import bokeh.plotting as bkplt
import bokeh.models as bkmod
from bokeh.io import output_notebook
import plotly.express as px

# Configure dask.
dask.config.set(scheduler=dask_scheduler)

# Ignore all warnings.
warnings.filterwarnings("ignore")

# Setup access to malariagen data.
results_cache_path = here() / "build" / "malariagen_data_cache"
ag3 = malariagen_data.Ag3(
    # Pin the version of the cohorts analysis for reproducibility.
    cohorts_analysis=cohorts_analysis,
    results_cache=results_cache_path.as_posix(),
)

# Read in the final cohorts dataframe.
final_cohorts_path = (
    here() / 
    "build" / 
    analysis_version / 
    "analysis" / 
    "final_cohorts.geojson"
)
gdf_cohorts = gpd.read_file(final_cohorts_path)

# Paths to H12 and G123 calibration outputs.
h12_calibration_dir = f"build/{analysis_version}/analysis/h12-calibration"
g123_calibration_dir = f"build/{analysis_version}/analysis/g123-calibration"


def stack_overlaps(df, start_col, end_col, tolerance=10000):
    """Stack overlapping objects."""
    occupants = [None]
    out = []
    for _, cur in df.iterrows():
        level = 0
        prv = occupants[level]
        # Search upwards to find the first vacant level.
        while prv is not None and cur[start_col] <= (prv[end_col] + tolerance):
            level += 1
            if level == len(occupants):
                occupants.append(None)
            prv = occupants[level]
        occupants[level] = cur
        out.append(level)
    return np.asarray(out)


def load_cohort_signals(contig, cohort_id):
    """Load selection signals for a given contig and cohort."""

    signals_path = (
        here()
        / "build"
        / analysis_version
        / "analysis"
        / "h12-signal-detection"
        / f"{cohort_id}_{contig}.csv"
    )
    try:
        df_signals = pd.read_csv(signals_path)
    except pd.errors.EmptyDataError:
        df_signals = pd.DataFrame()
    return df_signals


def load_signals(contig, start=None, stop=None):
    """Load all selection signals for a given genome region."""
    
    # Load signal dataframes for all cohorts.
    dfs = []
    for _, row in gdf_cohorts.iterrows():
        df = load_cohort_signals(contig=contig, cohort_id=row['cohort_id'])
        dfs.append(df)
    df_signals = pd.concat(dfs, axis=0).assign(statistic="H12")

    # Merge with cohorts data.
    df_signals = df_signals.merge(gdf_cohorts, on="cohort_id")
    
    # # Color by taxon.
    # color_dict = {
    #     'gambiae': '#BEC4FF',
    #     'coluzzii': '#D7B2A6',
    #     'arabiensis': '#A6D7CA',
    # }
    # df_signals['color'] = df_signals['taxon'].map(color_dict).fillna('lightgrey')
    
    # Fixed color.
    df_signals["color"] = "#D7B2A6"
    
    # Filter to region.
    if start and stop:
        df_signals = df_signals.query(
            f"focus_pstop < {int(stop)} and focus_pstart > {int(start)}"
        )
        
    # Sort and stack
    df_signals = df_signals.sort_values(by='span2_pstart')
    df_signals['level'] = stack_overlaps(df_signals, 'span2_pstart', 'span2_pstop')
    
    return df_signals


def plot_signals(
    df, 
    contig, 
    patch_height=0.7, 
    row_height=10,
    min_height=60,
    genes_height=80,
    x_min=None, 
    x_max=None,
):
    """Plot an overview of selection signals."""
    
    # Default to plotting the whole contig.
    if x_min is None:
        x_min = 0
    if x_max is None:
        x_max = ag3.genome_sequence(contig).shape[0]

    # Set up triangle shapes for bokeh patches glyphs.
    source = df.drop("geometry", axis=1).copy()
    source["left_xs"] = [
        np.array([row.span2_pstart, row.focus_pstart, row.focus_pstart])
        for idx, row in df.iterrows()
    ]
    source["left_ys"] = [
        np.array([row.level + patch_height / 2, row.level, row.level + patch_height])
        for idx, row in df.iterrows()
    ]
    source["right_xs"] = [
        np.array([row.focus_pstop, row.focus_pstop, row.span2_pstop])
        for idx, row in df.iterrows()
    ]
    source["right_ys"] = [
        np.array([row.level, row.level + patch_height, row.level + patch_height / 2])
        for idx, row in df.iterrows()
    ]
    source["center_xs"] = [
        np.array([row.pcenter, row.pcenter])
        for idx, row in df.iterrows()
    ]
    source["center_ys"] = [
        np.array([row.level, row.level + patch_height])
        for idx, row in df.iterrows()
    ]
    source["bottom"] = source["level"]
    source["mid"] = source["level"] + 0.5
    source["top"] = source["level"] + patch_height
    source["score"] = source["delta_i"].astype(int)
    source = bkmod.ColumnDataSource(data=source)

    hover = bkmod.HoverTool(
        tooltips=[
            ("Cohort", '@cohort_id'),
            ("Taxon", "@taxon"),
            ("Location", "@admin2_name, @admin1_name (@admin1_iso), @country"),
            ("Date", "@year quarter @quarter"),
            ("Statistic", '@statistic'),
            ("Score", '@score'),
            ("Focus", "@focus_pstart{,} - @focus_pstop{,} bp"),
        ],
    )

    xwheel_zoom = bkmod.WheelZoomTool(
        dimensions="width", maintain_focus=False
    )
    
    # make figure 
    fig1 = bkplt.figure(
        title='Selection signals',
        width=900, 
        height=min_height + (row_height * max(df.level)), 
        tools=["tap" ,"xpan", "xzoom_in", "xzoom_out","reset", xwheel_zoom, hover],
        toolbar_location='above', 
        active_drag='xpan', 
        x_range = bkmod.Range1d(x_min, x_max, bounds='auto'),
        y_range = bkmod.Range1d(patch_height - 1, max(df.level) + 1, bounds='auto'),
        active_scroll=xwheel_zoom,
    )

    fig1.patches(
        xs='left_xs', 
        ys='left_ys', 
        source=source, 
        color="color", 
        alpha=.7, 
        line_width=2, 
    )
    fig1.patches(
        xs='right_xs', 
        ys='right_ys', 
        source=source, 
        color="color", 
        alpha=.7, 
        line_width=2, 
    )

    fig1.quad(
        bottom='bottom', 
        top='top', 
        left='focus_pstart', 
        right='focus_pstop', 
        source=source, 
        color="red", 
        alpha=.5, 
        line_width=2,
    )

    glyph = bkmod.MultiLine(
        xs='center_xs', 
        ys='center_ys', 
        line_color='red', 
        line_width=2, 
        line_alpha=0.8,
    )
    fig1.add_glyph(source, glyph)
    
    # Tidy up the plot.
    fig1.yaxis.visible = False
    fig1.xaxis.visible = False
    fig1.ygrid.visible = False
    # fig1.legend.background_fill_alpha = 0.2
    url = '../cohort/@cohort.html'
    taptool = fig1.select(type=bkmod.TapTool)
    taptool.callback = bkmod.OpenURL(url=url)

    fig2 = ag3.plot_genes(
        region=contig, 
        sizing_mode="stretch_width",
        x_range=fig1.x_range,
        height=genes_height,
        show=False,
    )
    
    fig = bklay.gridplot(
        [fig1, fig2],
        ncols=1,
        toolbar_location="above",
        merge_tools=True,
        sizing_mode="stretch_width",
    ) 

    bkplt.show(fig)

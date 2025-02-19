# Utility variables and functions used in the site page notebooks.
# We expect this script to be executed via a %run magic command
# from within a Jupyter notebook.

# Expects that variables and functions defined in workflow/common/scripts/setup.py
# are available.

# Imports. Use "noqa" to mark imports that aren't used within this
# file but you want to be made available to the notebooks that run
# this file. (Otherwise they will get stripped out by ruff.)
from textwrap import dedent  # noqa
from IPython.display import Markdown, HTML  # noqa
from ipyleaflet import Map, Marker, basemaps, AwesomeIcon, GeoData  # noqa
from ipywidgets import HTML  # noqa
import bokeh.layouts as bklay
import bokeh.plotting as bkplt
import bokeh.models as bkmod
from bokeh.io import output_notebook  # noqa

# Read in the cohorts geojson.
gdf_cohorts = gpd.read_file(final_cohorts_geojson_file)


# Colours for signal plotting.
signal_span_color = "#D7B2A6"
signal_span_alpha = 0.6
signal_focus_color = "red"
signal_focus_alpha = 0.4
signal_center_color = "red"
signal_center_alpha = 1.0


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

    signals_path = h12_signal_files.as_posix().format(contig=contig, cohort=cohort_id)
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
        df = load_cohort_signals(contig=contig, cohort_id=row["cohort_id"])
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
    df_signals["color"] = signal_span_color

    # Filter to region.
    if start and stop:
        df_signals = df_signals.query(
            f"focus_pstop < {int(stop)} and focus_pstart > {int(start)}"
        )

    # Sort and stack
    df_signals = df_signals.sort_values(by="span2_pstart")
    df_signals["level"] = stack_overlaps(df_signals, "span2_pstart", "span2_pstop")

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
        np.array([row.pcenter, row.pcenter]) for idx, row in df.iterrows()
    ]
    source["center_ys"] = [
        np.array([row.level, row.level + patch_height]) for idx, row in df.iterrows()
    ]
    source["bottom"] = source["level"]
    source["mid"] = source["level"] + 0.5
    source["top"] = source["level"] + patch_height
    source["score"] = source["delta_i"].astype(int)
    source = bkmod.ColumnDataSource(data=source)

    hover = bkmod.HoverTool(
        tooltips=[
            ("Cohort", "@cohort_id"),
            ("Taxon", "@taxon"),
            ("Location", "@admin2_name, @admin1_name (@admin1_iso), @country"),
            ("Date", "@year quarter @quarter"),
            ("Statistic", "@statistic"),
            ("Score", "@score"),
            ("Focus", "@focus_pstart{,} - @focus_pstop{,} bp"),
        ],
    )

    xwheel_zoom = bkmod.WheelZoomTool(dimensions="width", maintain_focus=False)

    # make figure
    fig1 = bkplt.figure(
        title="Selection signals",
        width=900,
        height=min_height + (row_height * max(df.level)),
        tools=["tap", "xpan", "xzoom_in", "xzoom_out", "reset", xwheel_zoom, hover],
        toolbar_location="above",
        active_drag="xpan",
        x_range=bkmod.Range1d(x_min, x_max, bounds="auto"),
        y_range=bkmod.Range1d(patch_height - 1, max(df.level) + 1, bounds="auto"),
        active_scroll=xwheel_zoom,
    )

    fig1.patches(
        xs="left_xs",
        ys="left_ys",
        source=source,
        color=signal_span_color,
        alpha=signal_span_alpha,
        line_width=2,
    )
    fig1.patches(
        xs="right_xs",
        ys="right_ys",
        source=source,
        color=signal_span_color,
        alpha=signal_span_alpha,
        line_width=2,
    )

    fig1.quad(
        bottom="bottom",
        top="top",
        left="focus_pstart",
        right="focus_pstop",
        source=source,
        color=signal_focus_color,
        alpha=signal_focus_alpha,
        line_width=2,
    )

    glyph = bkmod.MultiLine(
        xs="center_xs",
        ys="center_ys",
        line_color=signal_center_color,
        line_width=2,
        line_alpha=signal_center_alpha,
    )
    fig1.add_glyph(source, glyph)

    # Tidy up the plot.
    fig1.yaxis.visible = False
    fig1.xaxis.visible = False
    fig1.ygrid.visible = False
    # fig1.legend.background_fill_alpha = 0.2
    url = "../cohort/@cohort_id.html"
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


default_basemap = basemaps.Esri.NatGeoWorldMap


def plot_cohorts_map(
    gdf_cohorts,
    center=None,
    zoom=3,
    basemap=default_basemap,
    url_prefix="",
):
    # Extract unique admin2 regions.
    gdf_admin2 = gdf_cohorts[
        [
            "country",
            "admin1_iso",
            "admin1_name",
            "admin2_name",
            "country_alpha2",
            "country_alpha3",
            "shapeID",
            "shapeGroup",
            "shapeType",
            "representative_lon",
            "representative_lat",
            "geometry",
        ]
    ].drop_duplicates()

    # Automatically determine center from data.
    if center is None:
        center = (
            gdf_admin2[["representative_lat", "representative_lon"]].mean().to_list()
        )

    # Create an ipyleaflet map.
    m = Map(center=center, zoom=zoom, basemap=basemap)

    # Plot the admin unit boundaries.
    geo_data = GeoData(
        geo_dataframe=gdf_admin2,
        style={
            "color": "black",
            "opacity": 1,
            "weight": 1,
            "fillColor": "#3366cc",
            "fillOpacity": 0.6,
        },
        # hover_style={
        #     'fillColor': 'red',
        #     'fillOpacity': 0.2,
        # },
        name="Level 2 administrative units",
    )
    m.add(geo_data)

    # Plot cohort markers.
    for index, df in gdf_cohorts.groupby(
        ["shapeID", "admin1_name", "admin1_iso", "admin2_name"]
    ):
        shape_id, admin1_name, admin1_iso, admin2_name = index
        if shape_id is None:
            continue
        country_name = df["country"].iloc[0]
        html_text = f"<strong>{admin2_name}, {admin1_name} ({admin1_iso}), {country_name}</strong>. Cohorts analysed:<br/>"

        for _, row in df.iterrows():
            if row.quarter > 0:
                link_text = (
                    f"{row.taxon} / {row.year} / Q{row.quarter} (n={row.cohort_size})"
                )
            else:
                link_text = f"{row.taxon} / {row.year} (n={row.cohort_size})"
            link_url = f"{url_prefix}cohort/{row.cohort_id}.html"
            html_text += f'<li><a href="{link_url}">{link_text}</a></li>'
        html_text += "</ul>"

        lat, lon = (
            df[["representative_lat", "representative_lon"]].drop_duplicates().values[0]
        )

        marker = Marker(
            location=(lat, lon),
            draggable=False,
            opacity=1,
            title=f"{admin2_name}, {admin1_name}, {country_name} - {len(df)} cohort{'s' if len(df) > 1 else ''} analysed - click for more information",
        )
        m.add(marker)
        message = HTML()
        message.value = html_text
        marker.popup = message

    return m

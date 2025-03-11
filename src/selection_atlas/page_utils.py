# Utility variables and functions used in the site page notebooks.

import numpy as np
import pandas as pd
import geopandas as gpd
import yaml
import bokeh.layouts as bklay
import bokeh.plotting as bkplt
import bokeh.models as bkmod
from ipyleaflet import Map, Marker, basemaps, GeoData
from ipywidgets import HTML

from .setup import AtlasSetup


default_basemap = basemaps.Esri.NatGeoWorldMap


class AtlasPageUtils:
    def __init__(
        self,
        setup: AtlasSetup,
    ):
        self.setup = setup

        # Read in the cohorts geojson.
        self._gdf_cohorts = None

        # Colours for signal plotting.
        self.signal_span_color = "#D7B2A6"
        self.signal_span_alpha = 0.6
        self.signal_focus_color = "red"
        self.signal_focus_alpha = 0.4
        self.signal_center_color = "red"
        self.signal_center_alpha = 1.0

        self.default_basemap = default_basemap

    @property
    def gdf_cohorts(self):
        if self._gdf_cohorts is None:
            self._gdf_cohorts = gpd.read_file(self.setup.final_cohorts_geojson_file)
        return self._gdf_cohorts

    def load_gwss_calibration(self, cohort_id):
        with open(self.setup.calibration_dir / f"{cohort_id}.yaml") as f:
            calibration_params = yaml.safe_load(f)
        return calibration_params

    def load_alert(self, alert_id):
        with open(self.setup.alerts_dir / f"{alert_id}.yaml", mode="r") as f:
            alert = yaml.safe_load(f)
        return alert

    def load_cohort_signals(self, contig, cohort_id):
        """Load selection signals for a given contig and cohort."""

        signals_path = self.setup.h12_signal_files.as_posix().format(
            contig=contig, cohort=cohort_id
        )
        try:
            df_signals = pd.read_csv(signals_path)
        except pd.errors.EmptyDataError:
            df_signals = pd.DataFrame()
        return df_signals

    def load_signals(self, contig, start=None, stop=None, query=None):
        """Load all selection signals for a given genome region."""

        # Load signal dataframes for all cohorts.
        dfs = []
        for _, row in self.gdf_cohorts.iterrows():
            df = self.load_cohort_signals(contig=contig, cohort_id=row["cohort_id"])
            dfs.append(df)
        df_signals = pd.concat(dfs, axis=0).assign(statistic="H12")

        # Merge with cohorts data.
        df_signals = df_signals.merge(self.gdf_cohorts, on="cohort_id")

        # Fixed color.
        df_signals["color"] = self.signal_span_color

        # Filter to region using an overlap query.
        if start and stop:
            df_signals = df_signals.query(
                f"focus_pstop > {int(start)} and focus_pstart < {int(stop)}"
            )

        # Apply optional query.
        if query is not None:
            df_signals = df_signals.query(query)

        # Sort and stack
        df_signals = df_signals.sort_values(by="span2_pstart")
        df_signals["level"] = stack_overlaps(df_signals, "span2_pstart", "span2_pstop")

        return df_signals

    def plot_signals(
        self,
        df,
        contig,
        patch_height=0.7,
        row_height=10,
        min_height=60,
        genes_height=80,
        x_min=None,
        x_max=None,
        gene_labels=None,
    ):
        """Plot an overview of selection signals."""

        # Default to plotting the whole contig.
        if x_min is None:
            x_min = 0
        if x_max is None:
            x_max = self.setup.malariagen_api.genome_sequence(contig).shape[0]

        # Set up triangle shapes for bokeh patches glyphs.
        source = df.drop("geometry", axis=1).copy()
        source["left_xs"] = [
            np.array([row.span2_pstart, row.focus_pstart, row.focus_pstart])
            for idx, row in df.iterrows()
        ]
        source["left_ys"] = [
            np.array(
                [row.level + patch_height / 2, row.level, row.level + patch_height]
            )
            for idx, row in df.iterrows()
        ]
        source["right_xs"] = [
            np.array([row.focus_pstop, row.focus_pstop, row.span2_pstop])
            for idx, row in df.iterrows()
        ]
        source["right_ys"] = [
            np.array(
                [row.level, row.level + patch_height, row.level + patch_height / 2]
            )
            for idx, row in df.iterrows()
        ]
        source["center_xs"] = [
            np.array([row.pcenter, row.pcenter]) for idx, row in df.iterrows()
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
            color=self.signal_span_color,
            alpha=self.signal_span_alpha,
            line_width=2,
        )
        fig1.patches(
            xs="right_xs",
            ys="right_ys",
            source=source,
            color=self.signal_span_color,
            alpha=self.signal_span_alpha,
            line_width=2,
        )

        fig1.quad(
            bottom="bottom",
            top="top",
            left="focus_pstart",
            right="focus_pstop",
            source=source,
            color=self.signal_focus_color,
            alpha=self.signal_focus_alpha,
            line_width=2,
        )

        glyph = bkmod.MultiLine(
            xs="center_xs",
            ys="center_ys",
            line_color=self.signal_center_color,
            line_width=2,
            line_alpha=self.signal_center_alpha,
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

        fig2 = self.setup.malariagen_api.plot_genes(
            region=contig,
            sizing_mode="stretch_width",
            x_range=fig1.x_range,
            height=genes_height,
            show=False,
            gene_labels=gene_labels,
        )

        fig = bklay.gridplot(
            [fig1, fig2],
            ncols=1,
            toolbar_location="above",
            merge_tools=True,
            sizing_mode="stretch_width",
        )

        bkplt.show(fig)

    def plot_cohorts_map(
        self,
        gdf_cohorts=None,
        center=None,
        zoom=3,
        basemap=default_basemap,
        url_prefix="",
    ):
        if gdf_cohorts is None:
            gdf_cohorts = self.gdf_cohorts

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
                gdf_admin2[["representative_lat", "representative_lon"]]
                .mean()
                .to_list()
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
                    link_text = f"{row.taxon} / {row.year} / Q{row.quarter} (n={row.cohort_size})"
                else:
                    link_text = f"{row.taxon} / {row.year} (n={row.cohort_size})"
                link_url = f"{url_prefix}cohort/{row.cohort_id}.html"
                html_text += f'<li><a href="{link_url}">{link_text}</a></li>'
            html_text += "</ul>"

            lat, lon = (
                df[["representative_lat", "representative_lon"]]
                .drop_duplicates()
                .values[0]
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

    def plot_locations_map(self, cohort, df_samples):
        df = (
            df_samples[["latitude", "longitude", "taxon"]]
            .groupby(["latitude", "longitude", "taxon"])
            .size()
            .to_frame()
            .rename(columns={0: "count"})
            .reset_index()
        )

        center = (df["latitude"].mean(), df["longitude"].mean())
        m = Map(center=center, zoom=9, basemap=self.default_basemap)

        for _, row in df.iterrows():
            lat, long = row[["latitude", "longitude"]]

            if row["taxon"] == "gambiae":
                color = "red"
            elif row["taxon"] == "coluzzii":
                color = "cadetblue"
            elif row["taxon"] == "arabiensis":
                color = "lightgreen"
            else:
                color = "gray"

            marker = Marker(
                location=(lat, long), draggable=False, opacity=0.7, color=color
            )
            m.add_layer(marker)
            message2 = HTML()
            message2.value = f"n = {row['count']}"
            marker.popup = message2

        return m

    def style_data_sources(self, df_samples, caption):
        release_prefix = {
            "agam": "Ag",
            "afun": "Af",
        }[self.setup.atlas_id]
        sample_set_citations = self.setup.sample_set_citations()

        def make_clickable_study(row):
            study_url = row["study_url"]
            # Deal with campos-2021 which has multiple URLs.
            study_url = study_url.split(", ")[0]
            study_id = row["study_id"]
            return f'<a href="{study_url}" target="_blank">{study_id}</a>'

        def make_clickable_release(row):
            release = release_prefix + row["release"]
            url = f"https://malariagen.github.io/vector-data/{release[:3].lower()}/{release.lower()}.html"
            return f'<a href="{url}" rel="noopener noreferrer" target="_blank">{release}</a>'

        def get_citations(row):
            sample_set = row["sample_set"]
            try:
                citations = sample_set_citations.loc[sample_set]
                if isinstance(citations, pd.DataFrame):
                    citations = [c for _, c in citations.iterrows()]
                else:
                    assert isinstance(citations, pd.Series)
                    citations = [citations]
            except KeyError:
                citations = []
            links = []
            for citation in citations:
                url = citation["citation_url"]
                author = citation["citation_author"]
                year = citation["citation_year"]
                link = f"<a href='{url}'>{author} ({year})</a>"
                links.append(link)
            content = ", ".join(links)
            return content

        # Prepare a table of sample sets.
        df_sources = (
            df_samples[
                ["sample_set", "study_id", "study_url", "contributor", "release"]
            ]
            .groupby("sample_set")
            .agg(
                {
                    "study_id": "first",
                    "study_url": "first",
                    # Some sample sets have multiple contributors.
                    "contributor": lambda x: ", ".join(set(x)),
                    "release": "first",
                }
            )
            .reset_index(drop=False)
        )

        # Get proper ordering of releases.
        release_split = (
            df_sources["release"]
            .str.split(".")
            .apply(lambda x: tuple([int(i) for i in x]))
        )
        df_sources["release_split"] = release_split

        # Make links clickable.
        df_sources["study_id"] = df_sources.apply(make_clickable_study, axis="columns")
        df_sources["release"] = df_sources.apply(make_clickable_release, axis="columns")
        df_sources["citations"] = df_sources.apply(get_citations, axis="columns")
        df_sources_style = (
            df_sources.sort_values(["release_split", "sample_set"])[
                ["sample_set", "study_id", "contributor", "release", "citations"]
            ]
            .rename(
                {
                    "sample_set": "Sample Set",
                    "study_id": "Study",
                    "contributor": "Contributor",
                    "release": "Data Release",
                    "citations": "Citations",
                },
                axis="columns",
            )
            .style.set_caption(caption)
            .set_table_styles(
                [
                    {"selector": "th", "props": "text-align: left; font-size: 1.1em;"},
                    {
                        "selector": "td",
                        "props": "text-align: left; font-weight: normal;",
                    },
                ],
                overwrite=False,
            )
            .hide(axis="index")
        )

        return df_sources_style


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

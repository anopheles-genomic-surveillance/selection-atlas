import numpy as np
import numba
import pandas as pd
import itertools
import functools
from pyprojroot import here
from bisect import bisect_left, bisect_right
import lmfit
import matplotlib.pyplot as plt


def exponential_peak(x, center, amplitude, decay, baseline, floor, ceiling):
    """Symmetric exponential peak function.

    Parameters
    ----------
    x : ndarray
        Independent variable.
    center : int or float
        The center of the peak.
    amplitude : float
        Amplitude parameter.
    decay : float
        Decay parameter.
    baseline : float
        Baseline parameter.
    floor : float
        Minimum value that the result can take.
    ceiling : float
        Maximum value that the result can take.

    Returns
    -------
    y : ndarray

    """

    # locate the index at which to split data into left and right flanks
    ix_split = bisect_right(x, center)

    # compute left flank
    xl = center - x[:ix_split]
    yl = baseline + amplitude * np.exp(-xl / decay)

    # compute right flank
    xr = x[ix_split:] - center
    yr = baseline + amplitude * np.exp(-xr / decay)

    # prepare output
    y = np.concatenate([yl, yr])

    # apply limits
    y = y.clip(floor, ceiling)

    return y


def skewed_exponential_peak(
    x, center, amplitude, decay, skew, baseline, floor, ceiling
):
    """Asymmetric exponential decay peak function.

    Parameters
    ----------
    x : ndarray
        Independent variable.
    center : int or float
        The center of the peak.
    amplitude : float
        Amplitude parameter.
    decay : float
        Decay parameter.
    skew : float
        Skew parameter.
    baseline : float
        Baseline parameter.
    floor : float
        Minimum value that the result can take.
    ceiling : float
        Maximum value that the result can take.

    Returns
    -------
    y : ndarray

    """

    decay_right = 2 ** (-skew) * decay
    decay_left = 2**skew * decay

    # locate the index at which to split data into left and right flanks
    ix_split = bisect_right(x, center)

    # compute left flank
    xl = center - x[:ix_split]
    yl = baseline + amplitude * np.exp(-xl / decay_left)

    # compute right flank
    xr = x[ix_split:] - center
    yr = baseline + amplitude * np.exp(-xr / decay_right)

    # prepare output
    y = np.concatenate([yl, yr])

    # apply limits
    y = y.clip(floor, ceiling)

    return y


def gaussian_peak(x, center, amplitude, sigma, baseline, floor, ceiling):
    """Gaussian peak function.

    Parameters
    ----------
    x : ndarray
        Independent variable.
    center : int or float
        The center of the peak.
    amplitude : float
        Amplitude parameter.
    sigma : float
        Width parameter.
    baseline : float
        Baseline parameter.
    floor : float
        Minimum value that the result can take.
    ceiling : float
        Maximum value that the result can take.

    Returns
    -------
    y : ndarray

    """

    y = baseline + amplitude * np.exp(-((x - center) ** 2) / (2 * sigma**2))

    # apply limits
    y = y.clip(floor, ceiling)

    return y


def skewed_gaussian_peak(x, center, amplitude, sigma, skew, baseline, floor, ceiling):
    """Asymmetric Gaussian peak function.

    Parameters
    ----------
    x : ndarray
        Independent variable.
    center : int or float
        The center of the peak.
    amplitude : float
        Amplitude parameter.
    sigma : float
        Width parameter.
    skew : float
        Skew parameter.
    baseline : float
        Baseline parameter.
    floor : float
        Minimum value that the result can take.
    ceiling : float
        Maximum value that the result can take.

    Returns
    -------
    y : ndarray

    """

    sigma_right = 2 ** (-skew) * sigma
    sigma_left = 2**skew * sigma

    # locate the index at which to split data into left and right flanks
    ix_split = bisect_right(x, center)

    # compute left flank
    xl = center - x[:ix_split]
    yl = baseline + amplitude * np.exp(-(xl**2) / (2 * sigma_left**2))

    # compute right flank
    xr = x[ix_split:] - center
    yr = baseline + amplitude * np.exp(-(xr**2) / (2 * sigma_right**2))

    # prepare output
    y = np.concatenate([yl, yr])

    # apply limits
    y = y.clip(floor, ceiling)

    return y


def fit_exponential_peak(
    setup,
    cohort_id,
    contig,
    gpos,
    stat_filtered,
    gcenter,
    gflank,
    scan_interval,
    init_amplitude,
    min_amplitude,
    max_amplitude,
    init_decay,
    min_decay,
    init_skew,
    min_skew,
    max_skew,
    init_baseline,
    min_baseline,
    max_baseline,
    min_delta_aic,
    min_stat_max,
    debug=False,
):
    # locate region to fit
    loc_region = slice(
        bisect_left(gpos, gcenter - gflank), bisect_right(gpos, gcenter + gflank)
    )

    # set up data to fit
    x = gpos[loc_region]
    y = stat_filtered[loc_region]

    # fit peak model
    peak_model = lmfit.Model(skewed_exponential_peak)
    peak_params = lmfit.Parameters()
    peak_params["center"] = lmfit.Parameter(
        "center", vary=True, value=gcenter, min=gcenter - gflank, max=gcenter + gflank
    )
    peak_params["amplitude"] = lmfit.Parameter(
        "amplitude",
        vary=True,
        value=init_amplitude,
        min=min_amplitude,
        max=max_amplitude,
    )
    peak_params["decay"] = lmfit.Parameter(
        "decay", vary=True, value=init_decay, min=min_decay, max=gflank / 3
    )
    peak_params["skew"] = lmfit.Parameter(
        "skew", vary=True, value=init_skew, min=min_skew, max=max_skew
    )
    peak_params["baseline"] = lmfit.Parameter(
        "baseline", vary=True, value=init_baseline, min=min_baseline, max=max_baseline
    )
    peak_params["ceiling"] = lmfit.Parameter("ceiling", vary=False, value=1)
    peak_params["floor"] = lmfit.Parameter("floor", vary=False, value=0)
    peak_result = peak_model.fit(y, x=x, params=peak_params)

    # fit null model
    null_model = lmfit.models.ConstantModel()
    null_params = lmfit.Parameters()
    null_params["c"] = lmfit.Parameter(
        "c", vary=True, value=init_baseline, min=0, max=1
    )
    null_result = null_model.fit(y, x=x, params=null_params)

    # compute fit
    peak_delta_i = int(null_result.aic - peak_result.aic)

    # determine if we want to emit a result - we will do this if delta_i is above threshold
    # and also only if the fitted peak center is within the scan interval - if it is beyond, then
    # we will get a better fit in a different scan interval
    fit_gcenter = peak_result.params["center"].value

    peak_in_scan_interval = (
        (gcenter - scan_interval) < fit_gcenter < (gcenter + scan_interval)
    )

    fit_params = peak_result.params
    fit_skew = fit_params["skew"].value
    fit_decay = fit_params["decay"].value
    decay_right = 2 ** (-fit_skew) * fit_decay
    decay_left = 2**fit_skew * fit_decay
    focus_gstart = fit_gcenter - 0.25 * decay_left
    focus_gstop = fit_gcenter + 0.25 * decay_right
    span1_gstart = fit_gcenter - 1 * decay_left
    span1_gstop = fit_gcenter + 1 * decay_right
    span2_gstart = fit_gcenter - 2 * decay_left
    span2_gstop = fit_gcenter + 2 * decay_right

    # Determine contig physical position.
    fit_pcenter = g2p(setup, contig, fit_gcenter)
    focus_pstart = g2p(setup, contig, focus_gstart)
    focus_pstop = g2p(setup, contig, focus_gstop)
    span1_pstart = g2p(setup, contig, span1_gstart)
    span1_pstop = g2p(setup, contig, span1_gstop)
    span2_pstart = g2p(setup, contig, span2_gstart)
    span2_pstop = g2p(setup, contig, span2_gstop)

    # Determine max value, pos max value (genetic, physical).
    loc_peak = slice(bisect_left(x, span2_gstart), bisect_right(x, span2_gstop))
    if loc_peak.stop == loc_peak.start:
        # In some rare cases, there are no data points within this
        # peak region. This is probably pathological, so don't output
        # a signal in this case.
        return
    x_peak = x[loc_peak]
    y_peak = y[loc_peak]
    loc_max = np.argmax(y_peak)
    gpos_max = x_peak[loc_max]
    ppos_max = g2p(setup, contig, gpos_max)
    stat_max = y_peak[loc_max]

    if (
        peak_delta_i > min_delta_aic
        and stat_max > min_stat_max
        and peak_in_scan_interval
    ):
        if debug:
            x_fitted = np.linspace(x[0], x[-1], 1000)
            y_fitted = skewed_exponential_peak(
                x=x_fitted,
                center=peak_result.params["center"].value,
                amplitude=peak_result.params["amplitude"].value,
                decay=peak_result.params["decay"].value,
                skew=peak_result.params["skew"].value,
                baseline=peak_result.params["baseline"].value,
                floor=peak_result.params["floor"].value,
                ceiling=peak_result.params["ceiling"].value,
            )
            delta_i = null_result.aic - peak_result.aic
            fig, ax = plt.subplots(facecolor="w", figsize=(6, 4))
            ax.plot(x, y, marker="o", linestyle=" ", mfc="none", markersize=2)
            ax.plot(x_fitted, y_fitted, marker=None, linestyle="--", color="k")
            ax.axvspan(
                fit_gcenter - decay_left,
                fit_gcenter + decay_right,
                zorder=0,
                color="red",
                alpha=0.2,
            )
            ax.axvspan(
                fit_gcenter - 2 * decay_left,
                fit_gcenter + 2 * decay_right,
                zorder=0,
                color="red",
                alpha=0.2,
            )
            ax.axvline(fit_gcenter, color="red", lw=2, zorder=0)
            ax.axhline(min_stat_max, color="k", lw=1, linestyle="--", zorder=0)
            ax.annotate(
                f"$n={x.shape[0]}$\n"
                + f"$AIC={peak_result.aic:.0f}$\n"
                + f"$BIC={peak_result.bic:.0f}$\n"
                + f"$\\chi^{2}={peak_result.chisqr:.3f}$\n"
                + f"$\\Delta_{{i}}={delta_i:.0f}$\n"
                + f"$\\Delta_{{i}} / n = {delta_i / x.shape[0]:.2f}$\n",
                xy=(0, 1),
                xycoords="axes fraction",
                xytext=(5, -5),
                textcoords="offset points",
                va="top",
                ha="left",
                fontsize=8,
            )
            ax.set_xlim(gcenter - gflank, gcenter + gflank)
            ax.set_ylim(0, 1)
            ax.set_ylabel("H12")
            ax.set_xlabel(f"Contig {contig} position (cM)")
            ax.set_title(f"center {gcenter}, flank {gflank}")
            fig.tight_layout()
            plt.show()
            plt.close()

            print(peak_result.fit_report())

        # build output record
        record = dict(
            cohort_id=cohort_id,
            contig=contig,
            gcenter=fit_gcenter,
            pcenter=fit_pcenter,
            delta_i=peak_delta_i,
            stat_max=stat_max,
            gpos_max=gpos_max,
            ppos_max=ppos_max,
            focus_gstart=focus_gstart,
            focus_gstop=focus_gstop,
            span1_gstart=span1_gstart,
            span1_gstop=span1_gstop,
            span2_gstart=span2_gstart,
            span2_gstop=span2_gstop,
            focus_pstart=focus_pstart,
            focus_pstop=focus_pstop,
            span1_pstart=span1_pstart,
            span1_pstop=span1_pstop,
            span2_pstart=span2_pstart,
            span2_pstop=span2_pstop,
            amplitude=fit_params["amplitude"].value,
            decay=fit_decay,
            skew=fit_skew,
            decay_left=decay_left,
            decay_right=decay_right,
            baseline=fit_params["baseline"].value,
            aic=peak_result.aic,
            bic=peak_result.bic,
            rss=peak_result.chisqr,
            constant_aic=null_result.aic,
            # params=fit_params,
            # result=peak_result,
        )

        return record


@numba.njit
def hampel_filter(x, size, t=3):
    # https://link.springer.com/article/10.1186/s13634-016-0383-6
    # https://towardsdatascience.com/outlier-detection-with-hampel-filter-85ddf523c73d

    y = x.copy()
    mad_scale_factor = 1.4826

    for i in range(size, len(x) - size):
        # window
        w = x[i - size : i + size]
        # window median
        m = np.median(w)
        # median absolute deviation
        mad = np.median(np.abs(w - m))
        # MAD scale estimate
        s = mad_scale_factor * mad
        # construct response
        if np.abs(x[i] - m) > (t * s):
            y[i] = m

    return y


@numba.njit
def recursive_hampel_filter(x, size, t=3):
    # https://link.springer.com/article/10.1186/s13634-016-0383-6
    # https://towardsdatascience.com/outlier-detection-with-hampel-filter-85ddf523c73d

    y = x.copy()
    mad_scale_factor = 1.4826

    for i in range(size, len(x) - size):
        # window
        w = y[i - size : i + size]
        # window median
        m = np.median(w)
        # median absolute deviation
        mad = np.median(np.abs(w - m))
        # MAD scale estimate
        S = mad_scale_factor * mad
        # construct response
        if np.abs(y[i] - m) > (t * S):
            y[i] = m

    return y


def read_gmap(setup, contig):
    atlas_id = setup.atlas_id
    if contig in {"2RL", "3RL"}:
        contig = contig[0]
        contig_r, contig_l = f"{contig}R", f"{contig}L"
        df_r = read_gmap(atlas_id, contig_r)
        df_l = read_gmap(atlas_id, contig_l)
        max_ppos = df_r["pposition"].iloc[-1]
        max_gpos = df_r["gposition"].iloc[-1]
        df_l = df_l.iloc[1:]
        df_l["pposition"] += max_ppos
        df_l["gposition"] += max_gpos
        df = pd.concat([df_r, df_l], axis=0, ignore_index=True)
    else:
        df = pd.read_csv(here() / f"resources/{atlas_id}_{contig}.gmap", sep="\t")
    return df


@functools.lru_cache(maxsize=None)
def load_gmap(setup, contig):
    # read in the genetic map file
    df_gmap = read_gmap(setup.atlas_id, contig)

    # set up an array of per-base recombination rate values
    rr = np.zeros(len(setup.malariagen_api.genome_sequence(contig)), dtype="f8")

    # fill in the recombination rate values from the genetic map file
    for row, next_row in zip(
        itertools.islice(df_gmap.itertuples(), 0, len(df_gmap) - 1),
        itertools.islice(df_gmap.itertuples(), 1, None),
    ):
        # N.B., the genetic map file is in units of cM / Mbp
        # we multiple by 1e-6 to convert to cM / bp
        rr[row.pposition - 1 : next_row.pposition] = row.rrate * 1e-6

    # compute mapping from physical to genetic position
    gmap = np.cumsum(rr)

    return gmap


def p2g(setup, contig, ppos):
    """Convert physical position (bp) to genetic position (cM)."""
    gmap = load_gmap(setup, contig)
    gpos = gmap[ppos - 1]
    return gpos


def g2p(setup, contig, gpos):
    gmap = load_gmap(setup, contig)
    ppos = bisect_left(gmap, gpos) + 1
    return ppos

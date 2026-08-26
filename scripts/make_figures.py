#!/usr/bin/env python3
"""Regenerate all summary tables and figures from raw CSV results.

Every number plotted/tabulated is read from results/raw/*.csv — nothing here
is hand-typed. Final comparison is K-means++ vs K-medoids only (see
docs/experiment_design.md). Presentation-visible text (titles, axis labels,
legends, the outlier table) is Ukrainian per project convention; code/columns
stay English.
"""
import argparse
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import scipy.stats as st

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

METHOD_LABELS = {"kmeans_pp": "K-means++", "kmedoids": "K-medoids"}
METHOD_LABELS_UA = {"kmeans_pp": "K-means++", "kmedoids": "K-медоїдів"}
METHOD_ORDER = ["kmeans_pp", "kmedoids"]
PRIMARY_METRIC = "max_route_time"
SCENARIO_KEY = ["scenario_type", "scenario_id", "outlier_rate", "M", "K", "method"]
NUMERIC_METRICS = ["max_route_time", "mean_route_time", "max_route_length",
                    "mean_route_length", "total_route_length", "cluster_time",
                    "routing_time", "total_computation_time", "capture_rate"]


def aggregate_over_seeds(df):
    """First aggregate repeated clustering_seed runs within each scenario+method
    (mean), so the main statistical summary is over independent scenarios,
    not pseudo-replicated clustering-seed x scenario rows."""
    if df.empty:
        return df
    keys = [k for k in SCENARIO_KEY if k in df.columns]
    metrics = [m for m in NUMERIC_METRICS if m in df.columns]
    return df.groupby(keys, as_index=False)[metrics].mean()


def make_main_summary(main_csv, out_dir):
    df = pd.read_csv(main_csv)
    if df.empty:
        print("skip main_summary: no valid rows")
        return None
    scen = aggregate_over_seeds(df)
    rows = []
    for (stype, method), g in scen.groupby(["scenario_type", "method"]):
        for metric in ["max_route_time", "mean_route_time", "max_route_length",
                       "mean_route_length", "cluster_time"]:
            vals = g[metric]
            n = len(vals)
            mean, sem = vals.mean(), (st.sem(vals) if n > 1 else 0.0)
            ci = st.t.interval(0.95, n - 1, loc=mean, scale=sem) if n > 1 and sem > 0 else (mean, mean)
            rows.append({"scenario_type": stype, "method": METHOD_LABELS[method], "metric": metric,
                         "n_scenarios": n, "mean": mean, "median": vals.median(), "std": vals.std(),
                         "min": vals.min(), "max": vals.max(), "ci95_lo": ci[0], "ci95_hi": ci[1]})
    out = out_dir / "main_summary.csv"
    pd.DataFrame(rows).to_csv(out, index=False)
    print(f"wrote {out}")
    return scen


def make_paired_comparisons(scen, out_dir):
    if scen is None or scen.empty:
        print("skip paired_comparisons: no data")
        return
    idx = ["scenario_type", "scenario_id", "outlier_rate", "M", "K"]
    metrics = ["max_route_time", "max_route_length", "mean_route_time",
               "mean_route_length", "cluster_time"]
    out_rows = []
    for key, g in scen.groupby(idx):
        sub = g.set_index("method")
        if "kmeans_pp" not in sub.index or "kmedoids" not in sub.index:
            continue
        row = dict(zip(idx, key if isinstance(key, tuple) else (key,)))
        for m in metrics:
            row[f"delta_{m}_kmeanspp_minus_kmedoids"] = sub.loc["kmeans_pp", m] - sub.loc["kmedoids", m]
        out_rows.append(row)
    out = out_dir / "paired_comparisons.csv"
    pd.DataFrame(out_rows).to_csv(out, index=False)
    print(f"wrote {out}")


def fig_main_comparison(scen, fig_dir):
    if scen is None or scen.empty:
        return
    stypes = sorted(scen["scenario_type"].unique())
    fig, axes = plt.subplots(2, 2, figsize=(10, 8))
    axes = np.atleast_1d(axes).flatten()
    for ax, stype in zip(axes, stypes):
        g = scen[scen["scenario_type"] == stype]
        data = [g[g["method"] == m][PRIMARY_METRIC] for m in METHOD_ORDER if m in g["method"].unique()]
        used = [METHOD_LABELS[m] for m in METHOD_ORDER if m in g["method"].unique()]
        ax.boxplot(data, tick_labels=used)
        ax.set_title(stype)
        ax.set_ylabel(PRIMARY_METRIC)
    for ax in axes[len(stypes):]:
        ax.axis("off")
    fig.suptitle("Main routing comparison (scenario-level, primary metric: max_route_time)")
    fig.tight_layout()
    for ext in ("png", "pdf"):
        p = fig_dir / f"main_routing_comparison.{ext}"
        fig.savefig(p)
        print(f"wrote {p}")
    plt.close(fig)


def make_outlier_1pct_table(outlier_csv, summary_dir, fig_dir, rate=0.01):
    df = pd.read_csv(outlier_csv)
    df = df[np.isclose(df["outlier_rate"], rate)]
    if df.empty:
        print(f"skip outlier_1pct_table: no rows with outlier_rate={rate} in {outlier_csv}")
        return
    scen = aggregate_over_seeds(df)
    M = int(scen["M"].iloc[0]) if not scen.empty else None
    K = int(scen["K"].iloc[0]) if not scen.empty else None

    rows_spec = [
        ("Перехоплено цілей", "capture_rate", "pct"),
        ("Середній час", "mean_route_time", "num"),
        ("Середня довжина", "mean_route_length", "num"),
        ("Максимальний час", "max_route_time", "num"),
        ("Максимальна довжина", "max_route_length", "num"),
    ]
    table_rows = []
    values = {m: {} for m in METHOD_ORDER}
    for label, metric, kind in rows_spec:
        for m in METHOD_ORDER:
            g = scen[scen["method"] == m]
            if g.empty:
                values[m][metric] = None
            else:
                values[m][metric] = g[metric].mean()
        table_rows.append((label, metric, kind))

    def fmt(v, kind):
        if v is None:
            return "N/A"
        return f"{100*v:.0f}%" if kind == "pct" else f"{v:.2f}"

    # CSV (English columns, from raw data only)
    csv_rows = []
    for label, metric, kind in table_rows:
        csv_rows.append({
            "Показник": label,
            "K-means++": values["kmeans_pp"][metric],
            "K-медоїдів": values["kmedoids"][metric],
        })
    out_csv = summary_dir / "outlier_1pct_table.csv"
    pd.DataFrame(csv_rows).to_csv(out_csv, index=False)
    print(f"wrote {out_csv}")

    # Academic Beamer-style table figure, Ukrainian labels
    col_labels = ["Показник", "K-means++", "K-медоїдів"]
    cell_text = []
    for label, metric, kind in table_rows:
        v_pp, v_km = values["kmeans_pp"][metric], values["kmedoids"][metric]
        cell_text.append([label, fmt(v_pp, kind), fmt(v_km, kind)])

    fig, ax = plt.subplots(figsize=(7, 3.2))
    fig.patch.set_facecolor("white")
    ax.set_facecolor("white")
    ax.axis("off")
    tbl = ax.table(cellText=cell_text, colLabels=col_labels, loc="center", cellLoc="center")
    tbl.auto_set_font_size(False)
    tbl.set_fontsize(13)
    tbl.scale(1, 2.0)
    for (r, c), cell in tbl.get_celld().items():
        cell.set_edgecolor("black")
        cell.set_linewidth(0.8)
        cell.set_facecolor("white")
        if r == 0:
            cell.set_text_props(weight="bold", color="black")
        else:
            cell.set_text_props(color="black")
    title = f"Вплив 1% викидів (M = {M}, K = {K})" if M is not None else "Вплив 1% викидів"
    ax.set_title(title, fontsize=14, color="black", pad=14)
    fig.tight_layout()
    for ext in ("png", "pdf"):
        p = fig_dir / f"outlier_1pct_table.{ext}"
        fig.savefig(p, dpi=(300 if ext == "png" else None), facecolor="white")
        print(f"wrote {p}")
    plt.close(fig)


def fig_outlier_robustness(outlier_csv, fig_dir):
    df = pd.read_csv(outlier_csv)
    if df.empty:
        print("skip outlier_robustness: no valid rows")
        return
    scen = aggregate_over_seeds(df)
    fig, ax = plt.subplots(figsize=(7, 5))
    fig.patch.set_facecolor("white")
    ax.set_facecolor("white")
    for method in METHOD_ORDER:
        g = scen[scen["method"] == method]
        if g.empty:
            continue
        stats = g.groupby("outlier_rate")[PRIMARY_METRIC].agg(["mean", "std", "count"]).reset_index()
        yerr = stats["std"] / stats["count"].clip(lower=1) ** 0.5
        ax.errorbar(100 * stats["outlier_rate"], stats["mean"], yerr=yerr, marker="o",
                     label=METHOD_LABELS_UA[method], color="black" if method == "kmedoids" else "dimgray",
                     linestyle="-" if method == "kmeans_pp" else "--")
    ax.set_xlabel("Частка викидів, %")
    ax.set_ylabel("Максимальний час маршруту")
    ax.set_title("Вплив викидів на максимальний час маршруту")
    ax.grid(True, linewidth=0.4, alpha=0.5)
    ax.legend()
    fig.tight_layout()
    for ext in ("png", "pdf"):
        p = fig_dir / f"outlier_robustness.{ext}"
        fig.savefig(p, dpi=(300 if ext == "png" else None), facecolor="white")
        print(f"wrote {p}")
    plt.close(fig)


def make_scalability_summary(scaling_csv, summary_dir):
    df = pd.read_csv(scaling_csv)
    if df.empty:
        print("skip scalability_summary: no valid rows")
        return None
    scen = aggregate_over_seeds(df)
    rows = []
    for (M, method), g in scen.groupby(["M", "method"]):
        rows.append({"M": M, "method": METHOD_LABELS[method], "n_scenarios": len(g),
                     "mean_cluster_time": g["cluster_time"].mean(), "std_cluster_time": g["cluster_time"].std(),
                     "mean_routing_time": g["routing_time"].mean(),
                     "mean_total_computation_time": g["total_computation_time"].mean()})
    out = summary_dir / "scalability_summary.csv"
    pd.DataFrame(rows).sort_values(["method", "M"]).to_csv(out, index=False)
    print(f"wrote {out}")
    return scen


def fig_runtime_scaling(scen, fig_dir):
    if scen is None or scen.empty:
        return
    K = int(scen["K"].iloc[0]) if "K" in scen.columns and not scen.empty else None
    fig, ax = plt.subplots(figsize=(7, 5))
    fig.patch.set_facecolor("white")
    ax.set_facecolor("white")
    for method in METHOD_ORDER:
        g = scen[scen["method"] == method]
        if g.empty:
            continue
        stats = g.groupby("M")["cluster_time"].mean().reset_index()
        ax.plot(stats["M"], stats["cluster_time"], marker="o",
                label=METHOD_LABELS_UA[method], color="black" if method == "kmedoids" else "dimgray",
                linestyle="-" if method == "kmeans_pp" else "--")
    ax.set_xscale("log")
    ax.set_yscale("log")
    ax.set_xlabel("Кількість цілей M")
    ax.set_ylabel("Час кластеризації, сек")
    title = f"Масштабованість алгоритмів (K = {K} БПЛА)" if K is not None else "Масштабованість алгоритмів"
    ax.set_title(title)
    ax.grid(True, which="both", linewidth=0.4, alpha=0.5)
    ax.legend()
    fig.tight_layout()
    for ext in ("png", "pdf"):
        p = fig_dir / f"scalability_K{K}.{ext}"
        fig.savefig(p, dpi=(300 if ext == "png" else None), facecolor="white")
        print(f"wrote {p}")
    plt.close(fig)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--raw-dir", default="results/raw")
    p.add_argument("--summary-dir", default="results/summary")
    p.add_argument("--fig-dir", default="results/figures")
    args = p.parse_args()

    raw = Path(args.raw_dir)
    summary_dir = Path(args.summary_dir)
    fig_dir = Path(args.fig_dir)
    summary_dir.mkdir(parents=True, exist_ok=True)
    fig_dir.mkdir(parents=True, exist_ok=True)

    main_csv = raw / "main_results.csv"
    outlier_csv = raw / "outlier_results.csv"
    scaling_csv = raw / "scalability_results.csv"

    if main_csv.exists():
        scen = make_main_summary(main_csv, summary_dir)
        make_paired_comparisons(scen, summary_dir)
        fig_main_comparison(scen, fig_dir)
    else:
        print(f"skip: {main_csv} not found")

    if outlier_csv.exists():
        make_outlier_1pct_table(outlier_csv, summary_dir, fig_dir, rate=0.01)
        fig_outlier_robustness(outlier_csv, fig_dir)
    else:
        print(f"skip: {outlier_csv} not found")

    if scaling_csv.exists():
        scen_scale = make_scalability_summary(scaling_csv, summary_dir)
        fig_runtime_scaling(scen_scale, fig_dir)
    else:
        print(f"skip: {scaling_csv} not found")


if __name__ == "__main__":
    main()

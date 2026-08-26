#!/usr/bin/env python3
"""Regenerate all summary tables and figures from raw CSV results.

Every number plotted/tabulated is read from results/raw/*.csv — nothing here
is hand-typed. Run after run_main_experiment.py / run_outlier_experiment.py /
run_scaling_experiment.py.
"""
import argparse
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd
import scipy.stats as st

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

METHOD_LABELS = {"kmeans": "K-means", "kmeans_pp": "K-means++", "kmedoids": "K-medoids"}
METHOD_ORDER = ["kmeans", "kmeans_pp", "kmedoids"]
PRIMARY_METRIC = "max_route_time"


def _labels(df):
    return [METHOD_LABELS[m] for m in df["method"]]


def make_stats_summary(main_csv, out_dir):
    df = pd.read_csv(main_csv)
    rows = []
    for (stype, method), g in df.groupby(["scenario_type", "method"]):
        for metric in [PRIMARY_METRIC, "total_time"]:
            vals = g[metric]
            n = len(vals)
            mean, sem = vals.mean(), st.sem(vals) if n > 1 else 0.0
            ci = st.t.interval(0.95, n - 1, loc=mean, scale=sem) if n > 1 and sem > 0 else (mean, mean)
            rows.append({
                "scenario_type": stype, "method": METHOD_LABELS[method], "metric": metric,
                "n": n, "mean": mean, "median": vals.median(), "std": vals.std(),
                "min": vals.min(), "max": vals.max(),
                "ci95_lo": ci[0], "ci95_hi": ci[1],
            })
    out = out_dir / "stats_summary.csv"
    pd.DataFrame(rows).to_csv(out, index=False)
    print(f"wrote {out}")
    return out


def make_paired_differences(main_csv, out_dir):
    df = pd.read_csv(main_csv)
    idx = ["scenario_id", "clustering_seed"]
    piv = df.pivot_table(index=idx, columns="method", values=PRIMARY_METRIC)
    rows = []
    if "kmeans_pp" in piv.columns and "kmeans" in piv.columns:
        piv["kmeans_pp_minus_kmeans"] = piv["kmeans_pp"] - piv["kmeans"]
    if "kmeans_pp" in piv.columns and "kmedoids" in piv.columns:
        piv["kmeans_pp_minus_kmedoids"] = piv["kmeans_pp"] - piv["kmedoids"]
    out = out_dir / "paired_differences.csv"
    piv.reset_index().to_csv(out, index=False)
    print(f"wrote {out}")
    return out


def make_presentation_table(main_csv, out_dir):
    df = pd.read_csv(main_csv)
    rows = []
    for method, g in df.groupby("method"):
        rows.append({
            "method": METHOD_LABELS[method],
            f"mean_{PRIMARY_METRIC}": g[PRIMARY_METRIC].mean(),
            f"std_{PRIMARY_METRIC}": g[PRIMARY_METRIC].std(),
            "mean_total_route_length": g["total_route_length"].mean(),
            "mean_cluster_time": g["cluster_time"].mean(),
            "mean_routing_time": g["routing_time"].mean(),
            "mean_cluster_size_std": g["cluster_size_std"].mean(),
        })
    order = {METHOD_LABELS[m]: i for i, m in enumerate(METHOD_ORDER)}
    rows.sort(key=lambda r: order.get(r["method"], 99))
    out = out_dir / "presentation_table.csv"
    pd.DataFrame(rows).to_csv(out, index=False)
    print(f"wrote {out}")
    return out


def fig_main_comparison(main_csv, fig_dir):
    df = pd.read_csv(main_csv)
    stypes = sorted(df["scenario_type"].unique())
    fig, axes = plt.subplots(2, 2, figsize=(10, 8), sharey=False)
    for ax, stype in zip(axes.flat, stypes):
        g = df[df["scenario_type"] == stype]
        data = [g[g["method"] == m][PRIMARY_METRIC] for m in METHOD_ORDER if m in g["method"].unique()]
        used = [METHOD_LABELS[m] for m in METHOD_ORDER if m in g["method"].unique()]
        ax.boxplot(data, tick_labels=used)
        ax.set_title(stype)
        ax.set_ylabel(PRIMARY_METRIC)
    for ax in axes.flat[len(stypes):]:
        ax.axis("off")
    fig.suptitle("Main routing comparison (primary metric: max_route_time)")
    fig.tight_layout()
    for ext in ("png", "pdf"):
        p = fig_dir / f"main_routing_comparison.{ext}"
        fig.savefig(p)
        print(f"wrote {p}")
    plt.close(fig)


def fig_outlier_robustness(outlier_csv, fig_dir):
    df = pd.read_csv(outlier_csv)
    fig, ax = plt.subplots(figsize=(7, 5))
    for method in METHOD_ORDER:
        g = df[df["method"] == method]
        if g.empty:
            continue
        stats = g.groupby("outlier_rate")[PRIMARY_METRIC].agg(["mean", "std", "count"]).reset_index()
        yerr = stats["std"] / stats["count"].clip(lower=1) ** 0.5
        ax.errorbar(stats["outlier_rate"], stats["mean"], yerr=yerr, marker="o", label=METHOD_LABELS[method])
    ax.set_xlabel("outlier rate")
    ax.set_ylabel(f"mean {PRIMARY_METRIC}")
    ax.set_title("Robustness to outliers")
    ax.legend()
    fig.tight_layout()
    for ext in ("png", "pdf"):
        p = fig_dir / f"outlier_robustness.{ext}"
        fig.savefig(p)
        print(f"wrote {p}")
    plt.close(fig)


def fig_runtime_scaling(scaling_csv, fig_dir):
    df = pd.read_csv(scaling_csv)
    fig, ax = plt.subplots(figsize=(7, 5))
    for method in METHOD_ORDER:
        g = df[df["method"] == method]
        if g.empty:
            continue
        stats = g.groupby("M")["cluster_time"].mean().reset_index()
        ax.plot(stats["M"], stats["cluster_time"], marker="o", label=METHOD_LABELS[method])
    ax.set_xlabel("M (number of targets)")
    ax.set_ylabel("mean clustering runtime (s)")
    ax.set_title("Computational scaling")
    ax.legend()
    fig.tight_layout()
    for ext in ("png", "pdf"):
        p = fig_dir / f"runtime_scaling.{ext}"
        fig.savefig(p)
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
    scaling_csv = raw / "scaling_results.csv"

    if main_csv.exists():
        make_stats_summary(main_csv, summary_dir)
        make_paired_differences(main_csv, summary_dir)
        make_presentation_table(main_csv, summary_dir)
        fig_main_comparison(main_csv, fig_dir)
    else:
        print(f"skip: {main_csv} not found")

    if outlier_csv.exists():
        fig_outlier_robustness(outlier_csv, fig_dir)
    else:
        print(f"skip: {outlier_csv} not found")

    if scaling_csv.exists():
        fig_runtime_scaling(scaling_csv, fig_dir)
    else:
        print(f"skip: {scaling_csv} not found")


if __name__ == "__main__":
    main()

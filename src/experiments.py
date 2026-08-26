"""Experiment orchestration shared by scripts/run_*.py.

Final experiments compare ONLY K-means++ ("kmeans_pp") and K-medoids
("kmedoids") — see docs/experiment_design.md. Standard random-init K-means
remains in src/clustering.py for correctness testing but is not part of the
final experiment pipeline.
"""
import time

import numpy as np
import pandas as pd

from .clustering import run_clustering
from .distances import pairwise_distance_matrix
from .metrics import RESULT_COLUMNS, build_result_row
from .routing import route_all_clusters
from .trajectories import DEPOT, T_HORIZON, V_UAV, feature_matrix, generate_scenario

FINAL_METHODS = ("kmeans_pp", "kmedoids")


def run_one(scenario_type, scenario_seed, clustering_seed, M, K, method,
            outlier_rate=0.0, uav_speed=V_UAV, depot=DEPOT, t_horizon=T_HORIZON,
            scenario_id=None, extra=None):
    """Run one (scenario, clustering_seed, method) instance end to end.

    t_horizon is used ONLY to build the clustering feature representation
    (feature_matrix); routing/interception is unbounded in time (see
    src/routing.py), so it is never capped by t_horizon.
    """
    targets = generate_scenario(scenario_type, M, K, scenario_seed, outlier_rate=outlier_rate)
    X = feature_matrix(targets, T=t_horizon)

    t0 = time.perf_counter()
    D = pairwise_distance_matrix(X) if method == "kmedoids" else None
    labels, _ = run_clustering(method, X, D, K, clustering_seed)
    cluster_time = time.perf_counter() - t0

    t0 = time.perf_counter()
    routes = route_all_clusters(labels, K, targets, uav_speed, depot, t_horizon=None)
    routing_time = time.perf_counter() - t0

    sid = scenario_id if scenario_id is not None else f"{scenario_type}_s{scenario_seed}"
    return build_result_row(sid, scenario_type, scenario_seed, clustering_seed,
                             M, K, method, cluster_time, routing_time, labels, routes,
                             outlier_rate=outlier_rate, extra=extra)


def split_valid_invalid(rows):
    """Split result rows into (valid, invalid) by capture_rate == 1.0.

    Invalid rows get a 'reason' field and must not be used in final
    scientific summaries/tables/figures (see docs/experiment_design.md).
    """
    valid, invalid = [], []
    for row in rows:
        if row["capture_rate"] == 1.0:
            valid.append(row)
        else:
            bad = dict(row)
            bad["reason"] = (
                f"n_unreached={row['n_unreached']} of n_targets={row['n_targets']} "
                "(capture_rate < 1.0; check V_UAV > target speed)"
            )
            invalid.append(bad)
    return valid, invalid


def scenario_seeds(base_seed, n_scenarios):
    rng = np.random.default_rng(base_seed)
    return rng.integers(0, 2 ** 31 - 1, size=n_scenarios).tolist()


def clustering_seeds(base_seed, n_seeds):
    rng = np.random.default_rng(base_seed + 1)
    return rng.integers(0, 2 ** 31 - 1, size=n_seeds).tolist()


def _to_df(rows, columns=RESULT_COLUMNS):
    if not rows:
        return pd.DataFrame(columns=columns)
    return pd.DataFrame(rows)


def save_invalid_runs(df_invalid, path="results/summary/invalid_runs.csv"):
    """Append invalid (capture_rate < 1.0) rows to the shared invalid-runs log.

    Never silently discards a failed run and never mixes invalid rows into
    the final scientific tables/figures.
    """
    from pathlib import Path
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    if df_invalid is None or len(df_invalid) == 0:
        return 0
    if p.exists():
        existing = pd.read_csv(p)
        combined = pd.concat([existing, df_invalid], ignore_index=True)
    else:
        combined = df_invalid
    combined.to_csv(p, index=False)
    return len(df_invalid)


def run_main_experiment(scenario_types, M, K, n_scenarios, n_seeds, base_seed=42,
                         methods=FINAL_METHODS):
    s_seeds = scenario_seeds(base_seed, n_scenarios)
    c_seeds = clustering_seeds(base_seed, n_seeds)
    rows = []
    for stype in scenario_types:
        for si, sseed in enumerate(s_seeds):
            scenario_id = f"{stype}_sc{si}_seed{sseed}"
            for cseed in c_seeds:
                for method in methods:
                    rows.append(run_one(stype, sseed, cseed, M, K, method,
                                         scenario_id=scenario_id))
    valid, invalid = split_valid_invalid(rows)
    return _to_df(valid), _to_df(invalid)


def run_outlier_experiment(outlier_rates, M, K, n_scenarios, n_seeds, base_seed=42,
                            scenario_type="clustered_position_direction", methods=FINAL_METHODS):
    s_seeds = scenario_seeds(base_seed, n_scenarios)
    c_seeds = clustering_seeds(base_seed, n_seeds)
    rows = []
    for rate in outlier_rates:
        for si, sseed in enumerate(s_seeds):
            scenario_id = f"outlier{rate}_sc{si}_seed{sseed}"
            for cseed in c_seeds:
                for method in methods:
                    rows.append(run_one(scenario_type, sseed, cseed, M, K, method,
                                         outlier_rate=rate, scenario_id=scenario_id))
    valid, invalid = split_valid_invalid(rows)
    return _to_df(valid), _to_df(invalid)


def run_scaling_experiment(M_values, K, n_scenarios, n_seeds, base_seed=42,
                            scenario_type="random_random", methods=FINAL_METHODS):
    s_seeds = scenario_seeds(base_seed, n_scenarios)
    c_seeds = clustering_seeds(base_seed, n_seeds)
    rows = []
    for M in M_values:
        for si, sseed in enumerate(s_seeds):
            scenario_id = f"scaling_M{M}_sc{si}_seed{sseed}"
            for cseed in c_seeds:
                for method in methods:
                    rows.append(run_one(scenario_type, sseed, cseed, M, K, method,
                                         scenario_id=scenario_id))
    valid, invalid = split_valid_invalid(rows)
    return _to_df(valid), _to_df(invalid)

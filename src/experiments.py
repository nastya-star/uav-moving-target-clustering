"""Experiment orchestration shared by scripts/run_*.py."""
import time

import numpy as np
import pandas as pd

from .clustering import METHODS, run_clustering
from .distances import pairwise_distance_matrix
from .metrics import build_result_row
from .routing import route_all_clusters
from .trajectories import DEPOT, T_HORIZON, V_UAV, feature_matrix, generate_scenario


def run_one(scenario_type, scenario_seed, clustering_seed, M, K, method,
            outlier_rate=0.0, uav_speed=V_UAV, depot=DEPOT, t_horizon=T_HORIZON,
            scenario_id=None, extra=None):
    targets = generate_scenario(scenario_type, M, K, scenario_seed, outlier_rate=outlier_rate)
    X = feature_matrix(targets, T=t_horizon)

    t0 = time.perf_counter()
    D = pairwise_distance_matrix(X) if method == "kmedoids" else None
    labels, _ = run_clustering(method, X, D, K, clustering_seed)
    cluster_time = time.perf_counter() - t0

    t0 = time.perf_counter()
    routes = route_all_clusters(labels, K, targets, uav_speed, depot, t_horizon)
    routing_time = time.perf_counter() - t0

    sid = scenario_id if scenario_id is not None else f"{scenario_type}_s{scenario_seed}"
    return build_result_row(sid, scenario_type, scenario_seed, clustering_seed,
                             M, K, method, cluster_time, routing_time, labels, routes,
                             extra=extra)


def scenario_seeds(base_seed, n_scenarios):
    rng = np.random.default_rng(base_seed)
    return rng.integers(0, 2 ** 31 - 1, size=n_scenarios).tolist()


def clustering_seeds(base_seed, n_seeds):
    rng = np.random.default_rng(base_seed + 1)
    return rng.integers(0, 2 ** 31 - 1, size=n_seeds).tolist()


def run_main_experiment(scenario_types, M, K, n_scenarios, n_seeds, base_seed=42,
                         methods=METHODS):
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
    return pd.DataFrame(rows, columns=list(rows[0].keys()) if rows else None)


def run_outlier_experiment(outlier_rates, M, K, n_scenarios, n_seeds, base_seed=42,
                            scenario_type="clustered_position_direction", methods=METHODS):
    s_seeds = scenario_seeds(base_seed, n_scenarios)
    c_seeds = clustering_seeds(base_seed, n_seeds)
    rows = []
    for rate in outlier_rates:
        for si, sseed in enumerate(s_seeds):
            scenario_id = f"outlier{rate}_sc{si}_seed{sseed}"
            for cseed in c_seeds:
                for method in methods:
                    rows.append(run_one(scenario_type, sseed, cseed, M, K, method,
                                         outlier_rate=rate, scenario_id=scenario_id,
                                         extra={"outlier_rate": rate}))
    return pd.DataFrame(rows)


def run_scaling_experiment(M_values, K, n_scenarios, n_seeds, base_seed=42,
                            scenario_type="random_random", methods=METHODS):
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
    return pd.DataFrame(rows)

"""Aggregate per-run metrics from clustering labels and routing output.

Only metrics actually computed by clustering.py/routing.py are reported here;
nothing is fabricated.
"""
import numpy as np

RESULT_COLUMNS = [
    "scenario_id", "scenario_type", "scenario_seed", "clustering_seed",
    "M", "K", "method",
    "cluster_time", "routing_time", "total_time",
    "max_route_time", "mean_route_time", "std_route_time",
    "max_route_length", "mean_route_length", "total_route_length", "std_route_length",
    "cluster_sizes", "cluster_size_std",
    "n_unreached",
]


def build_result_row(scenario_id, scenario_type, scenario_seed, clustering_seed,
                      M, K, method, cluster_time, routing_time, labels, routes,
                      extra=None):
    route_times = np.array([r["route_time"] for r in routes])
    route_lengths = np.array([r["route_length"] for r in routes])
    cluster_sizes = np.array([int(np.sum(labels == k)) for k in range(K)])
    n_unreached = int(sum(r["n_unreached"] for r in routes))

    row = {
        "scenario_id": scenario_id,
        "scenario_type": scenario_type,
        "scenario_seed": scenario_seed,
        "clustering_seed": clustering_seed,
        "M": M,
        "K": K,
        "method": method,
        "cluster_time": cluster_time,
        "routing_time": routing_time,
        "total_time": cluster_time + routing_time,
        "max_route_time": float(np.max(route_times)),
        "mean_route_time": float(np.mean(route_times)),
        "std_route_time": float(np.std(route_times)),
        "max_route_length": float(np.max(route_lengths)),
        "mean_route_length": float(np.mean(route_lengths)),
        "total_route_length": float(np.sum(route_lengths)),
        "std_route_length": float(np.std(route_lengths)),
        "cluster_sizes": ";".join(map(str, cluster_sizes.tolist())),
        "cluster_size_std": float(np.std(cluster_sizes)),
        "n_unreached": n_unreached,
    }
    if extra:
        row.update(extra)
    return row

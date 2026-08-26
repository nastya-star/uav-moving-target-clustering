import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from src.routing import intercept_time, route_all_clusters, route_cluster
from src.trajectories import T_HORIZON, generate_scenario


def test_intercept_time_stationary_target_analytical():
    # target at (10, 0), stationary; UAV at origin, speed 5 -> t* = 10/5 = 2.0
    t_star, pos, feasible = intercept_time(
        uav_pos=np.array([0.0, 0.0]), uav_time=0.0,
        target_pos0=np.array([10.0, 0.0]), target_vel=np.array([0.0, 0.0]),
        uav_speed=5.0,
    )
    assert feasible
    assert abs(t_star - 2.0) < 1e-9
    assert np.allclose(pos, [10.0, 0.0])


def test_intercept_time_receding_target_analytical():
    # target at (d0,0) moving away at speed v along +x; UAV speed V > v.
    # closing: d0 + v*t = V*t  =>  t* = d0 / (V - v)
    d0, v, V = 20.0, 3.0, 8.0
    t_star, pos, feasible = intercept_time(
        uav_pos=np.array([0.0, 0.0]), uav_time=0.0,
        target_pos0=np.array([d0, 0.0]), target_vel=np.array([v, 0.0]),
        uav_speed=V,
    )
    assert feasible
    expected = d0 / (V - v)
    assert abs(t_star - expected) < 1e-6


def test_routing_continues_beyond_clustering_horizon():
    # target reachable only after the clustering representation horizon T_HORIZON
    d0, v, V = 200.0, 3.0, 8.0
    expected_t = d0 / (V - v)
    assert expected_t > T_HORIZON  # confirms this exercises the beyond-horizon path

    unbounded = route_cluster([0], _one_target(d0, v), uav_speed=V,
                               depot=[0.0, 0.0], t_horizon=None)
    assert unbounded["n_unreached"] == 0
    assert unbounded["n_intercepted"] == 1
    assert abs(unbounded["route_time"] - expected_t) < 1e-6

    capped = route_cluster([0], _one_target(d0, v), uav_speed=V,
                            depot=[0.0, 0.0], t_horizon=T_HORIZON)
    assert capped["n_unreached"] == 1  # demonstrates the horizon WOULD have blocked it


class _Targets:
    def __init__(self, positions0, velocities):
        self.positions0 = positions0
        self.velocities = velocities


def _one_target(d0, v):
    return _Targets(np.array([[d0, 0.0]]), np.array([[v, 0.0]]))


def test_all_assigned_targets_eventually_intercepted():
    from src.clustering import run_clustering
    from src.distances import pairwise_distance_matrix
    from src.trajectories import DEPOT, V_UAV, feature_matrix

    targets = generate_scenario("clustered_position_direction", M=25, K=3, seed=4)
    X = feature_matrix(targets)
    for method in ("kmeans_pp", "kmedoids"):
        D = pairwise_distance_matrix(X) if method == "kmedoids" else None
        labels, _ = run_clustering(method, X, D, 3, seed=1)
        routes = route_all_clusters(labels, 3, targets, V_UAV, DEPOT, t_horizon=None)
        n_unreached = sum(r["n_unreached"] for r in routes)
        n_intercepted = sum(r["n_intercepted"] for r in routes)
        assert n_unreached == 0
        assert n_intercepted == targets.M

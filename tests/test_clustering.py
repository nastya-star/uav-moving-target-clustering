import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from src.clustering import METHODS, run_clustering
from src.distances import pairwise_distance_matrix
from src.trajectories import feature_matrix, generate_scenario


def _setup(M=40, K=4, seed=3):
    targets = generate_scenario("clustered_position_direction", M=M, K=K, seed=seed)
    X = feature_matrix(targets)
    D = pairwise_distance_matrix(X)
    return X, D, K


def test_every_target_assigned_exactly_once_and_k_clusters():
    X, D, K = _setup()
    for method in METHODS:
        labels, _ = run_clustering(method, X, D, K, seed=7)
        assert labels.shape[0] == X.shape[0]
        assert set(np.unique(labels)).issubset(set(range(K)))
        assert len(np.unique(labels)) <= K


def test_kmedoids_representatives_are_input_points():
    X, D, K = _setup()
    labels, medoids = run_clustering("kmedoids", X, D, K, seed=7)
    assert len(medoids) == K
    assert all(0 <= m < X.shape[0] for m in medoids)


def test_reproducible_under_identical_seed():
    X, D, K = _setup()
    for method in METHODS:
        labels1, _ = run_clustering(method, X, D, K, seed=11)
        labels2, _ = run_clustering(method, X, D, K, seed=11)
        assert np.array_equal(labels1, labels2)

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from src.distances import pairwise_distance_matrix
from src.trajectories import feature_matrix, generate_scenario


def test_distance_symmetric_and_self_zero():
    targets = generate_scenario("random_random", M=20, K=3, seed=1)
    X = feature_matrix(targets)
    D = pairwise_distance_matrix(X)
    assert (D >= 0).all()
    assert (abs(D - D.T) < 1e-9).all()
    for i in range(D.shape[0]):
        assert D[i, i] < 1e-9

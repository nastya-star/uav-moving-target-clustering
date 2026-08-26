import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from src.experiments import run_one
from src.metrics import RESULT_COLUMNS


def test_result_row_has_expected_identifiers():
    row = run_one("random_random", scenario_seed=1, clustering_seed=2, M=15, K=3, method="kmeans")
    for col in RESULT_COLUMNS:
        assert col in row


def test_reproducible_end_to_end():
    row1 = run_one("clustered_position", scenario_seed=5, clustering_seed=9, M=15, K=3, method="kmedoids")
    row2 = run_one("clustered_position", scenario_seed=5, clustering_seed=9, M=15, K=3, method="kmedoids")
    assert row1["max_route_time"] == row2["max_route_time"]
    assert row1["cluster_sizes"] == row2["cluster_sizes"]

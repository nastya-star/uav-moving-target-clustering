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


def test_full_capture_rate_for_final_methods():
    for method in ("kmeans_pp", "kmedoids"):
        row = run_one("random_random", scenario_seed=2, clustering_seed=3, M=20, K=4, method=method)
        assert row["n_unreached"] == 0
        assert row["n_intercepted"] == row["n_targets"] == 20
        assert row["capture_rate"] == 1.0

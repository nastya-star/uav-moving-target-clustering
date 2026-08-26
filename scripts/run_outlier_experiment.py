#!/usr/bin/env python3
"""Robustness-to-outliers experiment: K-means++ vs K-medoids only.

Default M/K match the central presentation experiment (M=2000, K=20,
outlier rates 0/1/5/10%) — see docs/experiment_design.md for the outlier
definition.

Examples:
    python scripts/run_outlier_experiment.py --quick
    python scripts/run_outlier_experiment.py                 # M=2000, K=20
"""
import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from src.experiments import run_outlier_experiment, save_invalid_runs


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--M", type=int, default=2000)
    p.add_argument("--K", type=int, default=20)
    p.add_argument("--n-scenarios", type=int, default=30)
    p.add_argument("--n-seeds", type=int, default=10)
    p.add_argument("--base-seed", type=int, default=42)
    p.add_argument("--outlier-rates", nargs="+", type=float, default=[0.0, 0.01, 0.05, 0.10])
    p.add_argument("--scenario-type", default="clustered_position_direction")
    p.add_argument("--output", default="results/raw/outlier_results.csv")
    p.add_argument("--quick", action="store_true")
    args = p.parse_args()

    if args.quick:
        args.M, args.n_scenarios, args.n_seeds = 30, 3, 2
        args.K = min(args.K, 4)

    df_valid, df_invalid = run_outlier_experiment(args.outlier_rates, args.M, args.K,
                                                   args.n_scenarios, args.n_seeds, args.base_seed,
                                                   scenario_type=args.scenario_type)
    n_bad = save_invalid_runs(df_invalid)
    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    df_valid.to_csv(out, index=False)
    print(f"wrote {len(df_valid)} valid rows to {out}")
    if n_bad:
        print(f"WARNING: {n_bad} invalid runs logged to results/summary/invalid_runs.csv")


if __name__ == "__main__":
    main()

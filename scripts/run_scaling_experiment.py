#!/usr/bin/env python3
"""Computational-cost scaling experiment (K-means++ vs K-medoids only) as M
(number of targets) grows, K fixed.

Examples:
    python scripts/run_scaling_experiment.py --quick
    python scripts/run_scaling_experiment.py --K 20
"""
import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from src.experiments import run_scaling_experiment, save_invalid_runs

DEFAULT_M_VALUES = [100, 150, 200, 300, 400, 500, 700, 1000, 1250, 1500, 1750, 2000]


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--M-values", nargs="+", type=int, default=DEFAULT_M_VALUES)
    p.add_argument("--K", type=int, default=20)
    p.add_argument("--n-scenarios", type=int, default=10)
    p.add_argument("--n-seeds", type=int, default=3)
    p.add_argument("--base-seed", type=int, default=42)
    p.add_argument("--scenario-type", default="random_random")
    p.add_argument("--output", default="results/raw/scalability_results.csv")
    p.add_argument("--quick", action="store_true")
    args = p.parse_args()

    if args.quick:
        args.M_values, args.n_scenarios, args.n_seeds = [50, 100, 200], 2, 2
        args.K = min(args.K, 4)

    df_valid, df_invalid = run_scaling_experiment(args.M_values, args.K, args.n_scenarios, args.n_seeds,
                                                   args.base_seed, scenario_type=args.scenario_type)
    n_bad = save_invalid_runs(df_invalid)
    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    df_valid.to_csv(out, index=False)
    print(f"wrote {len(df_valid)} valid rows to {out}")
    if n_bad:
        print(f"WARNING: {n_bad} invalid runs logged to results/summary/invalid_runs.csv")


if __name__ == "__main__":
    main()

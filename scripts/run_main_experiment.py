#!/usr/bin/env python3
"""Main K-means++ vs K-medoids routing comparison (final experiment: only
these two methods — see docs/experiment_design.md).

Examples:
    python scripts/run_main_experiment.py --quick
    python scripts/run_main_experiment.py --M 150 --K 5 --n-scenarios 30 --n-seeds 10
"""
import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from src.experiments import run_main_experiment, save_invalid_runs
from src.trajectories import SCENARIO_TYPES


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--M", type=int, default=150)
    p.add_argument("--K", type=int, default=5)
    p.add_argument("--n-scenarios", type=int, default=30)
    p.add_argument("--n-seeds", type=int, default=10)
    p.add_argument("--base-seed", type=int, default=42)
    p.add_argument("--scenario-types", nargs="+", default=list(SCENARIO_TYPES))
    p.add_argument("--output", default="results/raw/main_results.csv")
    p.add_argument("--quick", action="store_true", help="small debug run")
    args = p.parse_args()

    if args.quick:
        args.M, args.n_scenarios, args.n_seeds = 30, 3, 2
        args.K = min(args.K, 4)

    df_valid, df_invalid = run_main_experiment(args.scenario_types, args.M, args.K,
                                                args.n_scenarios, args.n_seeds, args.base_seed)
    n_bad = save_invalid_runs(df_invalid)
    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    df_valid.to_csv(out, index=False)
    print(f"wrote {len(df_valid)} valid rows to {out}")
    if n_bad:
        print(f"WARNING: {n_bad} invalid runs (capture_rate < 1.0) logged to "
              f"results/summary/invalid_runs.csv and excluded from {out}")
        if n_bad > 0.1 * (len(df_valid) + n_bad):
            print("STOP: more than 10% of runs are invalid — indicates a model "
                  "problem (check V_UAV vs target speed). Fix before proceeding.")
            sys.exit(1)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Run the main K-means vs K-means++ vs K-medoids routing comparison.

Examples:
    python scripts/run_main_experiment.py --quick
    python scripts/run_main_experiment.py --M 150 --K 5 --n-scenarios 30 --n-seeds 10
"""
import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from src.experiments import run_main_experiment
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
        args.K = min(args.K, 3)

    df = run_main_experiment(args.scenario_types, args.M, args.K,
                              args.n_scenarios, args.n_seeds, args.base_seed)
    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(out, index=False)
    print(f"wrote {len(df)} rows to {out}")


if __name__ == "__main__":
    main()

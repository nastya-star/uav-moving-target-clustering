#!/usr/bin/env python3
"""Computational-cost scaling experiment as M (number of targets) grows.

Examples:
    python scripts/run_scaling_experiment.py --quick
    python scripts/run_scaling_experiment.py --M-values 200 500 1000 2000
"""
import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from src.experiments import run_scaling_experiment


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--M-values", nargs="+", type=int, default=[200, 500, 1000, 2000])
    p.add_argument("--K", type=int, default=8)
    p.add_argument("--n-scenarios", type=int, default=10)
    p.add_argument("--n-seeds", type=int, default=3)
    p.add_argument("--base-seed", type=int, default=42)
    p.add_argument("--scenario-type", default="random_random")
    p.add_argument("--output", default="results/raw/scaling_results.csv")
    p.add_argument("--quick", action="store_true")
    args = p.parse_args()

    if args.quick:
        args.M_values, args.n_scenarios, args.n_seeds = [50, 100, 200], 2, 2
        args.K = min(args.K, 3)

    df = run_scaling_experiment(args.M_values, args.K, args.n_scenarios, args.n_seeds,
                                 args.base_seed, scenario_type=args.scenario_type)
    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(out, index=False)
    print(f"wrote {len(df)} rows to {out}")


if __name__ == "__main__":
    main()

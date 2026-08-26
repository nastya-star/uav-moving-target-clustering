# UAV Routing for Interception of Moving Targets: K-means++ vs. K-means vs. K-medoids

## Research question

Does K-means++ initialization improve the decomposition and final UAV routing
quality compared with standard K-means (random initialization) and K-medoids,
when used as the target-clustering stage of a two-level UAV routing algorithm
for moving-target interception? The comparison is made on the downstream
mission-level routing metric, not on internal clustering objectives.

This project studies the effect of K-means++ initialization on trajectory
clustering within a two-level UAV routing algorithm for moving targets and
compares its downstream routing performance, robustness, and computational
cost with standard K-means and K-medoids. **K-means++ is established prior
work**; the contribution here is the experimental study and comparison, not a
new clustering algorithm.

## Mathematical context

`K` UAVs must intercept `M >> K` moving targets with trajectories `z_j(t)`.
Targets are partitioned `S = S_1 ⊔ ... ⊔ S_K`, one part per UAV, and after
clustering the *same* interception-routing algorithm is applied to every
method. The mission objective is the slowest UAV's completion time,
`T_max = max_k T(S_k)`, reported as `max_route_time` (the primary metric,
since interception time is implemented in this project — see below).

Full mathematical model (trajectory representation, distance, clustering
methods, and the routing/interception model): **`docs/experiment_design.md`**.

> **Note on scope**: this repository started empty — no trajectory generator,
> distance function, clustering code, or UAV routing model previously
> existed. All of it, including the routing/interception model, was built for
> this study and is fully documented in `docs/experiment_design.md` rather
> than assumed or hidden.

## Compared methods

| Method | Initialization | Implementation |
|---|---|---|
| K-means (baseline) | random | `sklearn.cluster.KMeans(init="random", n_init=1)` |
| K-means++ | k-means++ | `sklearn.cluster.KMeans(init="k-means++", n_init=1)` |
| K-medoids | random medoids, alternating (PAM-style) updates | custom, `src/clustering.py`, on precomputed trajectory distances |

`n_init=1` for both K-means variants so a single initialization is evaluated
per run — this isolates the effect of the initialization rule.

## Experiment design

- Four scenario families (position/direction each random or clustered):
  `random_random`, `clustered_position`, `clustered_direction`,
  `clustered_position_direction`.
- Fairness: for a given `(scenario_seed, clustering_seed)`, all three methods
  see identical targets/trajectories, `K`, UAV speed/depot/time horizon, and
  the same greedy routing procedure — only the clustering method differs.
- Outlier-robustness experiment at outlier rates 0%, 1%, 5%, 10% (outlier
  definition in `docs/experiment_design.md`).
- Scaling experiment over `M` (number of targets) measuring clustering /
  routing / total runtime.
- All seeds are deterministic (`--base-seed`, default 42) and stored per
  result row for reproducibility and paired comparisons.

Details: `docs/experiment_design.md`.

## Installation

```bash
pip install -r requirements.txt
```

## Quick run (debug, small scale)

```bash
python scripts/run_main_experiment.py --quick
python scripts/run_outlier_experiment.py --quick
python scripts/run_scaling_experiment.py --quick
python scripts/make_figures.py
```

## Full experiments

```bash
python scripts/run_main_experiment.py            # default M=150, K=5, 30 scenarios x 10 seeds x 3 methods
python scripts/run_outlier_experiment.py          # outlier rates 0/1/5/10%
python scripts/run_scaling_experiment.py          # M in {200,500,1000,2000}
python scripts/make_figures.py
```

Key CLI arguments (all scripts): `--M`, `--K`, `--n-scenarios`, `--n-seeds`,
`--base-seed`, `--output`, `--quick`.

The full-scale runs above are computationally heavier than `--quick`; check
expected runtime on your machine before launching the full versions.

## Outputs

- `results/raw/*.csv` — raw per-run metrics (one row per scenario x seed x
  method); regenerable, see `.gitignore`.
- `results/summary/stats_summary.csv` — mean/median/std/min/max + 95% CI per
  `(scenario_type, method)` for the primary metric and runtime.
- `results/summary/paired_differences.csv` — paired differences
  (K-means++ − K-means, K-means++ − K-medoids) on the primary metric, matched
  by `scenario_id` + `clustering_seed`.
- `results/summary/presentation_table.csv` — one row per method, generated
  from raw data only.
- `results/figures/main_routing_comparison.{png,pdf}`,
  `outlier_robustness.{png,pdf}`, `runtime_scaling.{png,pdf}`.

## Reproducibility

- All scenario and clustering seeds are derived deterministically from
  `--base-seed` (default 42) via `numpy.random.default_rng` and stored in
  every result row.
- Every number in every figure/table is computed from `results/raw/*.csv`;
  nothing is hand-typed. Regenerate summaries/figures at any time with
  `python scripts/make_figures.py`.
- `results/raw/*.csv` is excluded from version control (regenerable, and
  full-scale runs can be large); `results/summary/` and `results/figures/`
  from a `--quick` validation run are committed as a working example.

## Tests

```bash
python -m pytest tests/
```

Covers: distance symmetry/self-zero, every target assigned exactly once,
exactly K clusters/representatives, K-medoids representatives are real input
points, end-to-end reproducibility under identical seeds, and result-row
schema.

## Citation / references

- Arthur, D. and Vassilvitskii, S. (2007). *k-means++: The Advantages of
  Careful Seeding.* SODA.
- Kaufman, L. and Rousseeuw, P.J. (1990). *Finding Groups in Data: An
  Introduction to Cluster Analysis* (PAM algorithm).
- Pedregosa et al. (2011). *Scikit-learn: Machine Learning in Python.* JMLR.

## Status

**Preliminary.** This repository provides the experimental framework and a
small `--quick` validation run. Statistically meaningful conclusions require
running the full-scale experiments (`--quick` omitted) and are not yet
included.

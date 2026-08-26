# UAV Routing for Interception of Moving Targets: K-means++ vs. K-medoids

## Research question

How does K-means with K-means++ initialization compare with K-medoids when
trajectory clustering is used as the decomposition stage of UAV routing for
interception of moving targets? The comparison is made on downstream
mission-level routing outcomes (interception completeness, route time, route
length, runtime), not on internal clustering objectives, which are not
directly comparable between the two methods.

**Final scope**: the final experiment, tables, and figures compare exactly
**K-means++ vs. K-medoids**. Standard random-initialized K-means remains in
`src/clustering.py` only to test shared clustering-correctness properties; it
is excluded from `src/experiments.py:FINAL_METHODS` and from every final
result. K-means++ is established prior work (Arthur & Vassilvitskii, 2007),
not a new algorithm proposed by this project.

## Mathematical context

`K` UAVs must intercept `M >> K` moving targets with trajectories `z_j(t)`.
Targets are partitioned `S = S_1 ⊔ ... ⊔ S_K`, one part per UAV, and after
clustering the *same* interception-routing algorithm is applied to every
method. The mission objective is the slowest UAV's completion time,
`T_max = max_k T(S_k)`, reported as `max_route_time` (the primary metric).

Full mathematical model: **`docs/experiment_design.md`** — trajectory
representation, distance, both clustering methods, and the interception
model, including the proof that every target is eventually interceptable
whenever `V_uav >` target speed.

## 100% interception requirement

A run is scientifically valid only if every assigned target is intercepted:
`n_unreached == 0`, `n_intercepted == n_targets`, `capture_rate == 1.0`. This
holds by construction here because `V_uav` exceeds the maximum target speed
(see the interception proof in `docs/experiment_design.md`) and
routing/interception is **not** capped by the clustering representation
horizon (see below) — a UAV keeps flying until its assigned targets are all
caught. Every run's `n_targets`/`n_intercepted`/`n_unreached`/`capture_rate`
are recorded; any run with `capture_rate < 1.0` is written to
`results/summary/invalid_runs.csv` with a reason and excluded from all final
CSVs/tables/figures rather than silently dropped.

## Trajectory representation vs. routing horizon

`T_HORIZON` in `src/trajectories.py` is only the time span sampled to build
the shared clustering feature vector (`feature_matrix`, `L=6` grid points).
It is **not** a UAV routing deadline — `src/routing.py` takes an optional
`t_horizon` cutoff that defaults to unbounded, so interception can and does
continue past `T_HORIZON` when needed.

## Compared methods

| Method (`method=`) | Initialization | Implementation |
|---|---|---|
| `kmeans_pp` (K-means++) | k-means++ | `sklearn.cluster.KMeans(init="k-means++", n_init=1)` |
| `kmedoids` (K-medoids) | random medoids, alternating (Voronoi-iteration) updates | custom, `src/clustering.py`, on precomputed trajectory distances — **not** classic PAM BUILD+SWAP (documented in `docs/experiment_design.md`) |

Both receive the identical trajectory feature representation and distance
(`src/distances.py`).

## Experiment design

- Four scenario families: `random_random`, `clustered_position`,
  `clustered_direction`, `clustered_position_direction` (the last uses one
  latent per-target cluster label driving both position and direction —
  documented in `docs/experiment_design.md`).
- Fairness: identical targets/trajectories, `K`, UAV speed/depot, and routing
  procedure across both methods for a given `(scenario_seed, clustering_seed)`.
- Repeated clustering seeds (K-means++ and this K-medoids implementation are
  both stochastic) are aggregated (mean) **within each scenario first**;
  scientific summaries and paired comparisons are then computed over the
  independent scenarios, not over scenario×seed rows.
- Outlier-robustness at rates 0/1/5/10% (outlier definition: initial position
  redrawn from a domain expanded 2x and re-centered — see
  `docs/experiment_design.md`), with a central presentation result at
  `M=2000, K=20, outlier_rate=1%`.
- Scalability over `M in {100,...,2000}` at fixed `K=20`.
- All seeds deterministic from `--base-seed` (default 42) and stored per row.

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
python scripts/run_main_experiment.py            # M=150, K=5, 30 scenarios x 10 seeds
python scripts/run_scaling_experiment.py          # K=20, M in {100..2000}
python scripts/run_outlier_experiment.py          # M=2000, K=20, outlier rates 0/1/5/10%
python scripts/make_figures.py
```

Key CLI arguments (all scripts): `--M`, `--K`, `--n-scenarios`, `--n-seeds`,
`--base-seed`, `--output`, `--quick`.

## Outputs

- `results/raw/main_results.csv`, `scalability_results.csv`,
  `outlier_results.csv` — raw per-run metrics, valid runs only.
- `results/summary/invalid_runs.csv` — any run with `capture_rate < 1.0`
  (should not occur; present only to surface a model problem, never silently
  discarded).
- `results/summary/main_summary.csv`, `scalability_summary.csv` —
  scenario-level mean/median/std/min/max/95% CI.
- `results/summary/paired_comparisons.csv` — per-scenario paired differences
  (K-means++ − K-medoids).
- `results/summary/outlier_1pct_table.csv` +
  `results/figures/outlier_1pct_table.{png,pdf}` — the Ukrainian presentation
  table (`Вплив 1% викидів (M = 2000, K = 20)`).
- `results/figures/scalability_K20.{png,pdf}` — Ukrainian scalability graph
  (`Масштабованість алгоритмів (K = 20 БПЛА)`, log-log, `clustering_time`).
- `results/figures/outlier_robustness.{png,pdf}` — Ukrainian robustness graph.

Code, docs, and CSV column names are English; only presentation-visible text
(figure titles, axis labels, legends, the outlier table) is Ukrainian.

## Reproducibility

Every number in every table/figure is computed from `results/raw/*.csv`;
nothing is hand-typed. Regenerate at any time with
`python scripts/make_figures.py`. All scenario/clustering seeds derive
deterministically from `--base-seed` via `numpy.random.default_rng` and are
stored in every result row.

## Tests

```bash
python -m pytest tests/
```

Covers: distance symmetry/self-zero, every target assigned exactly once,
exactly K clusters/representatives, K-medoids representatives are real input
points, an analytical interception-time check, routing continuing past the
clustering representation horizon, 100% capture under `V_uav >` target speed,
end-to-end reproducibility, and result-row schema.

## Citation / references

- Arthur, D. and Vassilvitskii, S. (2007). *k-means++: The Advantages of
  Careful Seeding.* SODA.
- Kaufman, L. and Rousseeuw, P.J. (1990). *Finding Groups in Data* (PAM).
- Pedregosa et al. (2011). *Scikit-learn.* JMLR.

## Status

**Preliminary.** This repository provides the experimental framework and
validated small/medium runs. No conclusion about which method performs
better is stated here; that is a separate interpretation step over the
generated results.

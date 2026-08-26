# Experiment Design

## Status of the repository at project start

The repository was empty (no prior code, data, or figures). There was no existing
trajectory generator, distance function, clustering code, or UAV routing/interception
algorithm to reuse. Every component below is therefore a new, from-scratch
implementation built for this study, not a reuse of prior project code. The
routing/interception model in particular is an original but standard/simple
construction (see "Routing and interception model") documented here in full because
no such model previously existed in the repository.

## Research question

Does K-means++ initialization improve the decomposition and final UAV routing
quality compared with standard K-means (random init) and K-medoids, when used as
the target-clustering stage of a two-level UAV routing algorithm for moving-target
interception?

## Trajectory model

Each target `j` follows a constant-velocity (linear) trajectory over a fixed time
horizon `[0, T]`:

```
z_j(t) = p_j + v_j * t,   t in [0, T]
```

with `p_j` the initial 2D position and `v_j` a 2D velocity vector with speed drawn
from `[v_min, v_max]`. Constant-velocity motion is the simplest model consistent
with the mathematical setting in the task (an integral-distance over trajectories)
and keeps interception geometrically solvable in closed form (see below).

## Trajectory representation and distance

Both clustering methods receive the identical representation: each trajectory is
sampled on a common time grid `t_1, ..., t_L` (`L = 6`, evenly spaced over `[0, T]`),
giving a feature vector

```
x_j = (z_j(t_1), ..., z_j(t_L))  in R^(2L)
```

The trajectory distance is the discretized form of `D(i,j) = ∫ d(z_i(t),z_j(t)) rho(t) dt`
using a uniform `rho` and `d` = Euclidean distance, approximated by the RMS distance
over the grid:

```
D(i,j) = sqrt( (1/L) * sum_l || z_i(t_l) - z_j(t_l) ||^2 )  =  || x_i - x_j ||_2 / sqrt(L)
```

This is a positive scalar multiple of the Euclidean norm on `x`, hence a proper
metric (symmetric, zero iff identical on the grid, satisfies the triangle
inequality). K-means and K-means++ (scikit-learn) cluster the raw feature vectors
`x_j` under Euclidean distance, which is exactly `sqrt(L) * D`; K-medoids clusters
the precomputed pairwise matrix `D`. Both methods therefore use the same trajectory
information and the same underlying notion of distance — only the cluster-center
model differs (mean-in-feature-space vs. an actual medoid trajectory).

## Clustering methods

1. **K-means (baseline)**: `sklearn.cluster.KMeans(n_clusters=K, init="random", n_init=1, random_state=seed)`.
2. **K-means++**: identical call with `init="k-means++"`.
   `n_init=1` for both so a single initialization is evaluated — this isolates the
   effect of the initialization rule itself rather than averaging over restarts.
3. **K-medoids**: a compact "alternating" (Voronoi-iteration) PAM-style algorithm
   implemented in `src/clustering.py` against the precomputed distance matrix `D`:
   random medoid seeding (from `clustering_seed`) → assign each point to its
   nearest medoid → replace each medoid by the cluster member minimizing total
   in-cluster distance → repeat to convergence. Medoids are always actual input
   trajectories. The classic PAM BUILD+SWAP search is not used because its
   `O(K (M-K)^2)` per-iteration cost is impractical at `M` up to 2000 in the
   scaling experiment; the alternating variant is the standard, correct,
   scalable substitute and is documented here for transparency.

## Two-level routing / interception model (newly built — none existed)

All UAVs launch from a common depot at time `t=0`. All `K` UAVs share the same
constant speed `V_uav`, set above the maximum target speed so interception is
generally feasible. Defaults (`src/trajectories.py`): domain `100x100`, depot
at the domain center, `T_HORIZON = 20`, `V_uav = 8`, target speed in `[1, 3]`
— chosen so that the reachable radius `V_uav * T_HORIZON` comfortably covers
the domain diagonal from the central depot; `n_unreached` in the results
confirms how many targets, if any, fall outside the feasible envelope for a
given run.

Given a UAV at position `p` and time `t`, and a target with trajectory
`z(s) = p_0 + v*s`, the earliest interception time `t* >= t` solves

```
|| p_0 + v*t* - p || = V_uav * (t* - t)
```

which, writing `s = t* - t` and `d0 = p_0 + v*t - p`, is the quadratic

```
(v·v - V_uav^2) s^2 + 2 (d0·v) s + d0·d0 = 0
```

solved in closed form for the smallest non-negative root with `t* <= T`; if no
such root exists the target is marked unreachable from that state.

**Within-cluster routing**: targets assigned to a UAV are visited using a greedy
nearest-interception-time heuristic (at each step, intercept whichever remaining
target in the cluster can be reached soonest from the UAV's current
position/time). This is a simple, standard heuristic for the moving-target TSP
(exact optimization is NP-hard); the same heuristic is applied identically after
every clustering method, so it cannot bias the comparison.

`T(S_k)` = the time at which UAV `k` completes interception of the last target in
its cluster. The mission objective is

```
T_max = max_k T(S_k)
```

reported as `max_route_time`, the **primary metric** (interception time is
implemented, so `max_route_time` is used per the task's rule, not
`max_route_length`). `route_length` (flight path length) is also recorded per UAV;
since UAVs always fly at constant speed `V_uav` toward the next interception,
`route_length_k ≈ V_uav * route_time_k`, so the two are expected to be nearly
proportional in this model — both are still reported since they are both
model outputs, not fabricated.

## Outlier definition

An outlier target is one whose *initial position* is drawn uniformly from an
expanded domain (2x the normal spatial extent, re-centered) instead of from the
scenario's normal (clustered or uniform) position distribution, independent of the
other targets. A fraction `outlier_rate` of the `M` targets are replaced this way.
This produces targets that are spatially far from the natural cluster structure and
are the case the clustering stage is stress-tested against. Outlier velocities are
drawn from the same distribution as normal targets (only position is perturbed) so
the manipulation isolates spatial-structure robustness.

## Scenario families

All four families are supported by the generator in `src/trajectories.py`:

- `random_random`: initial positions uniform over the domain; velocity directions uniform random.
- `clustered_position`: initial positions drawn from `K` Gaussian blobs; velocity directions uniform random.
- `clustered_direction`: initial positions uniform; velocity headings drawn from `K` preferred directions plus angular noise.
- `clustered_position_direction`: both position and direction clustered.

## Fairness

Every method, for a given `(scenario_seed, clustering_seed)` pair, receives exactly
the same `M` targets/trajectories, the same `K`, the same `V_uav`/depot/time
horizon, and the same greedy routing procedure after clustering. Only the
clustering method/initialization differs. All seeds are stored per result row.

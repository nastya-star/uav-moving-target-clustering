"""Moving-target trajectory generation.

Targets follow constant-velocity trajectories z_j(t) = p_j + v_j * t over
[0, T_HORIZON]. See docs/experiment_design.md for the full model.
"""
from dataclasses import dataclass

import numpy as np

AREA_SIZE = 100.0
DEPOT = np.array([AREA_SIZE / 2, AREA_SIZE / 2])
# T_HORIZON is only the trajectory-REPRESENTATION horizon used to sample the
# feature grid for clustering (see feature_matrix below). It is NOT a
# deadline for UAV interception/routing, which is unbounded in time as long
# as V_UAV > target speed (see src/routing.py and docs/experiment_design.md).
T_HORIZON = 20.0
L_GRID = 6
V_TARGET_MIN = 1.0
V_TARGET_MAX = 3.0
V_UAV = 8.0  # > V_TARGET_MAX so every target is eventually interceptable

SCENARIO_TYPES = (
    "random_random",
    "clustered_position",
    "clustered_direction",
    "clustered_position_direction",
)


@dataclass
class Targets:
    positions0: np.ndarray  # (M, 2)
    velocities: np.ndarray  # (M, 2)
    scenario_type: str
    scenario_seed: int
    M: int
    K: int


def _random_positions(rng, m, area=AREA_SIZE):
    return rng.uniform(0, area, size=(m, 2))


def _clustered_positions(rng, m, k, assign, area=AREA_SIZE, spread=None):
    if spread is None:
        spread = area * 0.06
    centers = rng.uniform(area * 0.15, area * 0.85, size=(k, 2))
    pos = centers[assign] + rng.normal(0, spread, size=(m, 2))
    return np.clip(pos, 0, area)


def _random_velocities(rng, m, vmin=V_TARGET_MIN, vmax=V_TARGET_MAX):
    speeds = rng.uniform(vmin, vmax, size=m)
    angles = rng.uniform(0, 2 * np.pi, size=m)
    return np.stack([speeds * np.cos(angles), speeds * np.sin(angles)], axis=1)


def _clustered_velocities(rng, m, k, assign, vmin=V_TARGET_MIN, vmax=V_TARGET_MAX, angle_noise=0.25):
    headings = rng.uniform(0, 2 * np.pi, size=k)
    angles = headings[assign] + rng.normal(0, angle_noise, size=m)
    speeds = rng.uniform(vmin, vmax, size=m)
    return np.stack([speeds * np.cos(angles), speeds * np.sin(angles)], axis=1)


def _inject_outliers(rng, positions, outlier_rate, area=AREA_SIZE):
    m = positions.shape[0]
    n_out = int(round(outlier_rate * m))
    if n_out == 0:
        return positions, np.zeros(m, dtype=bool)
    idx = rng.choice(m, size=n_out, replace=False)
    lo, hi = -area * 0.5, area * 1.5  # expanded domain, 2x extent, re-centered
    positions = positions.copy()
    positions[idx] = rng.uniform(lo, hi, size=(n_out, 2))
    is_outlier = np.zeros(m, dtype=bool)
    is_outlier[idx] = True
    return positions, is_outlier


def generate_scenario(scenario_type, M, K, seed, outlier_rate=0.0):
    if scenario_type not in SCENARIO_TYPES:
        raise ValueError(f"unknown scenario_type {scenario_type!r}")
    rng = np.random.default_rng(seed)

    if scenario_type == "random_random":
        pos = _random_positions(rng, M)
        vel = _random_velocities(rng, M)
    elif scenario_type == "clustered_position":
        pos = _clustered_positions(rng, M, K, rng.integers(0, K, size=M))
        vel = _random_velocities(rng, M)
    elif scenario_type == "clustered_direction":
        pos = _random_positions(rng, M)
        vel = _clustered_velocities(rng, M, K, rng.integers(0, K, size=M))
    else:  # clustered_position_direction: ONE latent cluster label c_i in {1..K}
        # drives both the position cluster and the direction cluster, so a
        # target's position-cluster and direction-cluster always coincide
        # (no independent K^2 position x direction combinations).
        assign = rng.integers(0, K, size=M)
        pos = _clustered_positions(rng, M, K, assign)
        vel = _clustered_velocities(rng, M, K, assign)

    if outlier_rate > 0:
        pos, _ = _inject_outliers(rng, pos, outlier_rate)

    return Targets(positions0=pos, velocities=vel, scenario_type=scenario_type,
                    scenario_seed=seed, M=M, K=K)


def time_grid(L=L_GRID, T=T_HORIZON):
    return np.linspace(0, T, L)


def feature_matrix(targets: Targets, L=L_GRID, T=T_HORIZON):
    """x_j = (z_j(t_1), ..., z_j(t_L)) in R^(2L), shared by all clustering methods."""
    ts = time_grid(L, T)
    # (M, L, 2) = pos0 + vel * t
    traj = targets.positions0[:, None, :] + targets.velocities[:, None, :] * ts[None, :, None]
    return traj.reshape(targets.M, L * 2)

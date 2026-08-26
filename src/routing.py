"""Two-level routing: interception geometry + greedy per-cluster sequencing.

See docs/experiment_design.md ("Two-level routing / interception model") for
the closed-form derivation. This is a newly built model (none existed in the
repository) and is applied identically after every clustering method.
"""
import numpy as np


def intercept_time(uav_pos, uav_time, target_pos0, target_vel, uav_speed, t_horizon):
    """Earliest t* >= uav_time with |target_pos0 + target_vel*t* - uav_pos| =
    uav_speed*(t* - uav_time), t* <= t_horizon. Returns (t_star, position, feasible)."""
    d0 = target_pos0 + target_vel * uav_time - uav_pos
    v = target_vel
    a = v @ v - uav_speed ** 2
    b = 2 * (d0 @ v)
    c = d0 @ d0

    roots = []
    if abs(a) < 1e-12:
        if abs(b) > 1e-12:
            roots = [-c / b]
    else:
        disc = b * b - 4 * a * c
        if disc >= 0:
            sq = np.sqrt(disc)
            roots = [(-b - sq) / (2 * a), (-b + sq) / (2 * a)]

    feasible_s = [s for s in roots if s >= -1e-9]
    if not feasible_s:
        return None, None, False
    s = min(feasible_s)
    s = max(s, 0.0)
    t_star = uav_time + s
    if t_star > t_horizon + 1e-9:
        return None, None, False
    pos = target_pos0 + target_vel * t_star
    return t_star, pos, True


def route_cluster(member_indices, targets, uav_speed, depot, t_horizon):
    """Greedy nearest-interception-time routing for one UAV/cluster.

    Returns dict with route_time, route_length, n_intercepted, n_unreached,
    order (list of target indices in visiting order).
    """
    remaining = list(member_indices)
    pos_cur = np.array(depot, dtype=float)
    t_cur = 0.0
    route_length = 0.0
    order = []

    while remaining:
        best = None
        for idx in remaining:
            t_star, pos, feasible = intercept_time(
                pos_cur, t_cur, targets.positions0[idx], targets.velocities[idx],
                uav_speed, t_horizon,
            )
            if feasible and (best is None or t_star < best[0]):
                best = (t_star, pos, idx)
        if best is None:
            break  # no remaining target is reachable within the horizon
        t_star, pos, idx = best
        route_length += float(np.linalg.norm(pos - pos_cur))
        pos_cur, t_cur = pos, t_star
        order.append(idx)
        remaining.remove(idx)

    return {
        "route_time": t_cur,
        "route_length": route_length,
        "n_intercepted": len(order),
        "n_unreached": len(remaining),
        "order": order,
    }


def route_all_clusters(labels, K, targets, uav_speed, depot, t_horizon):
    """Route one UAV per cluster k=0..K-1. Returns list of per-cluster route dicts."""
    routes = []
    for k in range(K):
        members = np.where(labels == k)[0]
        if len(members) == 0:
            routes.append({"route_time": 0.0, "route_length": 0.0,
                            "n_intercepted": 0, "n_unreached": 0, "order": []})
            continue
        routes.append(route_cluster(members, targets, uav_speed, depot, t_horizon))
    return routes

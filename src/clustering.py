"""Three clustering methods sharing the same trajectory representation.

- kmeans_random: standard K-means, random initialization (baseline).
- kmeans_pp: K-means, k-means++ initialization.
- kmedoids: alternating (Voronoi-iteration) PAM-style K-medoids on a
  precomputed trajectory-distance matrix; medoids are always real data points.
See docs/experiment_design.md for details and rationale.
"""
import numpy as np
from sklearn.cluster import KMeans

METHODS = ("kmeans", "kmeans_pp", "kmedoids")


def run_kmeans(X, K, seed, init="random"):
    km = KMeans(n_clusters=K, init=init, n_init=1, random_state=seed, max_iter=300)
    labels = km.fit_predict(X)
    return labels, km.cluster_centers_


def run_kmedoids(D, K, seed, max_iter=100):
    """Alternating K-medoids on precomputed distance matrix D (M, M)."""
    rng = np.random.default_rng(seed)
    n = D.shape[0]
    medoids = rng.choice(n, size=K, replace=False)
    labels = np.argmin(D[:, medoids], axis=1)
    for _ in range(max_iter):
        new_medoids = medoids.copy()
        for k in range(K):
            members = np.where(labels == k)[0]
            if len(members) == 0:
                continue  # keep previous medoid for an empty cluster
            sub = D[np.ix_(members, members)]
            costs = sub.sum(axis=1)
            new_medoids[k] = members[np.argmin(costs)]
        new_labels = np.argmin(D[:, new_medoids], axis=1)
        converged = np.array_equal(new_medoids, medoids) and np.array_equal(new_labels, labels)
        medoids, labels = new_medoids, new_labels
        if converged:
            break
    return labels, medoids


def run_clustering(method, X, D, K, seed):
    """Dispatch by method name. Returns (labels, centers_or_medoid_indices)."""
    if method == "kmeans":
        return run_kmeans(X, K, seed, init="random")
    if method == "kmeans_pp":
        return run_kmeans(X, K, seed, init="k-means++")
    if method == "kmedoids":
        return run_kmedoids(D, K, seed)
    raise ValueError(f"unknown method {method!r}")

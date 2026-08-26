"""Pairwise trajectory distance: discretized RMS Euclidean distance over a
common time grid. See docs/experiment_design.md."""
import numpy as np
from scipy.spatial.distance import pdist, squareform

from .trajectories import L_GRID


def pairwise_distance_matrix(X, L=L_GRID):
    """X: (M, 2L) feature matrix from trajectories.feature_matrix.
    Returns the (M, M) matrix D(i,j) = ||x_i - x_j||_2 / sqrt(L)."""
    return squareform(pdist(X, metric="euclidean")) / np.sqrt(L)

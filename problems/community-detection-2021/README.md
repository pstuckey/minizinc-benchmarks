# Constrained Community Detection in Graphs

## Overview

This MiniZinc model solves the **Constrained Community Detection Problem**. The goal is to partition the nodes of a graph into groups (called _communities_) in a way that maximises a quality measure called **modularity**, while also respecting user-provided constraints about which nodes must or must not share a community.

Community detection is widely used in social network analysis, biological network clustering, and graph-based machine learning, where identifying tightly connected subgroups can reveal meaningful structure in data.

This version is updated to use strong typing and more modern data structures

---

## Problem Description

Given a graph with `n` nodes and up to `k` communities, the task is to assign each node to a community such that:

- The **modularity** of the resulting partition is as high as possible.
- Pairs of nodes listed in the **must-link** constraints are assigned to the _same_ community.
- Pairs of nodes listed in the **cannot-link** constraints are assigned to _different_ communities.

Modularity is a well-known measure from network science that rewards partitions where there are more edges within communities than would be expected by chance in a random graph with the same degree sequence.

---

## Parameters

| Parameter     | Description                                                                                                                                                                                         |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `N`           | Number of nodes in the graph                                                                                                                                                                        |
| `max_communities`           | Maximum number of communities allowed                                                                                                                                                 |
| `same_community`         | Pairs of nodes that must be in the same community                                                                                                                                        |
| `diff_community`         | Pairs of nodes that must be in a different community                                                                                                                                     |
| `A[i,j]`      | Adjacency matrix: `A[i,j] = 1` if there is an edge between nodes `i` and `j`                                                                                                                        |
| `B[i,j]`      | Weight matrix used in the modularity objective (integer version of modularity) |
| `k[i]`      | Degree of node `i` (number of edges incident to it)                                                                                                                                                 |

---

## Decision Variables

| Variable    | Description                                                                 |
| ----------- | --------------------------------------------------------------------------- |
| `x[i]`      | The community label assigned to node `i`, an integer in `1..k`              |
| `objective` | The modularity score for the partition (to be maximised)                    |

---

## Objective

The model **maximises** the `objective`, which is computed as:

$$
\text{objective} = 2 \sum_{\substack{i,j \in 1..n \\ j < i}} \mathbf{1}[x_i = x_j] \cdot B_{ij} + \sum_{i=1}^{n} B_{ii}
$$

Here, $\mathbf{1}[x_i = x_j]$ is 1 if nodes $i$ and $j$ are in the same community and 0 otherwise. In other words, the model rewards placing nodes together when the corresponding entry in `B` is positive (more internal edges than expected) and penalises doing so when it is negative.

The diagonal term (`dum = sum_i B[i,i]`) accounts for self-loop corrections in the weight matrix.

---

## Constraints

1. **Must-Link**: For each pair in `same_community`, the two nodes are forced into the same community.
2. **Cannot-Link**: For each pair in `diff_community`, the two nodes are forced into different communities.
4. **Symmetry breaking**: A `seq_precede_chain` constraint ensures community labels are assigned in order, eliminating equivalent solutions that differ only in how communities are numbered.

---



## References

- Newman, M. E. J. (2006). _Modularity and community structure in networks_. Proceedings of the National Academy of Sciences, 103(23), 8577–8582.
- Wagstaff, K., Cardie, C., Rogers, S., & Schrödl, S. (2001). _Constrained K-means Clustering with Background Knowledge_. ICML 2001. (Background on must-link/cannot-link constraints.)
- Guns, T., Dries, A., Tack, G., Nijssen, S., & De Raedt, L. (2013). _MiningZinc: A declarative framework for constraint-based pattern mining_. IJCAI 2013.

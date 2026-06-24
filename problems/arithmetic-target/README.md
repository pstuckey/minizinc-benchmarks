# Arithmetic Target

## Overview

This model solves the **Arithmetic Target Problem**, a puzzle where you combine a set of numbers using basic arithmetic operations to reach (or get as close as possible to) a target value. It is similar in spirit to the well-known television game show _Countdown_, in which contestants use a selection of numbers and the four arithmetic operations to reach a randomly chosen target.

The model works by building a **binary expression tree**: a tree-shaped structure where the leaves hold individual numbers from the input list, and the internal (branch) nodes represent arithmetic operations applied to their children. Evaluating the tree from top to bottom yields the final result.

---

## Problem Description

**Given:**

- A list of integers (`numbers`).
- A target integer (`target`).

**Goal:**

- Use each number **at most once**.
- Combine numbers using **addition (+)**, **subtraction (−)**, **multiplication (×)**, and **integer division (÷)**.
- Division is only permitted when the result is exact (i.e. no remainder).
- **Minimise** the difference between the computed result and the target, while also preferring to use as few numbers as possible.

---

## Parameters

| Parameter | Description                                  |
| --------- | -------------------------------------------- |
| `numbers` | Array of input integers to choose from       |
| `target`  | The desired result to reach                  |
| `n`       | Number of input integers (`length(numbers)`) |

---

## Decision Variables

The core of the model is a binary expression tree stored as a flat array of up to `2*n - 1` nodes (the maximum number of nodes in a full binary tree with `n` leaves).

| Variable       | Description                                                                                   |
| -------------- | --------------------------------------------------------------------------------------------- |
| `tree[i]`      | The type of node `i`: one of `Val` (a number), `Add`, `Sub`, `Mul`, `Div`, or `Null` (unused) |
| `left[i]`      | Index of the left child of node `i`                                                |
| `right[i]`     | Index of the right child of node `i`                                               |
| `value[i]` | The numerical value computed by the subtree rooted at node `i`                                |
| `root`         | The root node of the expression tree                                                      |
| `used`         | How many input numbers are used in the expression                                             |

---

## Constraints

1. **Tree shape**: Each internal node has exactly two children, and leaves have none. Global cardinality constraints prevent a node appearing as child of two nodes.
2. **Value propagation**: Each node's value (`tree_vals[i]`) is computed from its children according to its operation, or directly if it is a leaf if its used.
3. **Integer division**: When division is used, the numerator must be exactly divisible by the denominator.

5. **Symmetry breaking**: A large number of additional constraints are included to avoid counting equivalent expressions more than once. These cover:
   - Commutativity of addition and multiplication (`a + b` is the same as `b + a`).
   - Associativity of chains of the same operation.
   - Removal of trivial identities such as adding or multiplying by zero or one.
   - Canonical ordering of operands for symmetric operations.
---

## Objective

The model minimises:

$$
\text{objective} = 10 \times |\,\text{value}[root] - \text{target}\,| + \text{used}
$$

The factor of 10 ensures that **closeness to the target** is the primary goal, while the `used` term serves as a tiebreaker that prefers solutions using **fewer numbers**. The root of the tree (`value[root]`) is the final computed result.

---

## Example

For `numbers = [1, 2, 2, 3, 3, 5, 6, 6, 7, 8, 9]` and `target = 4108`, the model searches for an arithmetic expression using some or all of those numbers that produces a value as close to 4108 as possible.

---

## Notes

- The model is licensed under the MIT License (Copyright © 2022 Kelvin Davis).
- The flat-array representation of a binary tree is a compact way to encode tree structure without requiring pointer-based data structures.
- The many symmetry-breaking constraints are important for performance: without them, many structurally identical expressions would be explored repeatedly. 
- If an exact solution exists (objective = `used`), it will be found; otherwise the closest achievable result is returned.

---

## References

- The problem is closely related to the **Countdown numbers game** described in:
  > S. Hutton, "The Countdown Problem," _Journal of Functional Programming_, 12(6):609–616, 2002. [doi:10.1017/S0956796801004300](https://doi.org/10.1017/S0956796801004300)
- Expression tree search and arithmetic puzzle solving are also studied in the context of **program synthesis** and **symbolic regression**.

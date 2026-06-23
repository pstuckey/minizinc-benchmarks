# Trucking (MiniZinc model) — Beginner-friendly explanation

## What problem is this model solving?
This model chooses which trucks to use in each time period so that transport demand is met at minimum cost.

You are given:
- `T` time periods,
- `N` trucks,
- each truck’s load capacity (`Loads[i]`) and cost per use (`Cost[i]`),
- demand per period (`Demand[t]`).

The model decides, for each truck and each time period, whether the truck is used (`true`) or not (`false`).

---

## Main decision variables
- `x[i,t]` (Boolean):
  - `true` if truck `i` is used in period `t`
  - `false` otherwise
- `total_cost` (integer): total cost of all selected truck usages

So the key decision is the Boolean usage matrix `x` of size `N × T`.

---

## Core constraints (plain language)
1. **Demand must be covered every period**
   - For each time period `t`, the total transported load from selected trucks must be at least `Demand[t]`.
   - Formula idea: sum of `Loads[i] * x[i,t]` over all trucks `i` is `>= Demand[t]`.

2. **Special spacing rule for `Truck1`**
   - In any 3 consecutive periods, `Truck1` can appear at most once.
   - This enforces rest/cooldown-like spacing for that truck.

3. **Special spacing rule for `Truck2`**
   - In any 2 consecutive periods, `Truck2` can appear at most once.
   - This is a slightly weaker spacing than the `Truck1` rule.

---

## Objective
The model **minimizes total cost**:
- `total_cost = sum over all trucks and periods of Cost[i] * x[i,t]`
- Solver goal: choose feasible truck usage with the smallest `total_cost`.

---

## Input data you need
To run this model, data must provide at least:
- `T`, `N`
- truck indices for `Truck1`, `Truck2` (as values in `1..N`)
- arrays `Demand[1..T]`, `Cost[1..N]`, `Loads[1..N]`

---




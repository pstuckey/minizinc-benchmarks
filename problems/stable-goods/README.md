# Stable Goods

## Overview

This model describes a **stable allocation of indivisible goods with limited supply**. There are several people, several types of goods, and a fixed number of copies available for each good. Each person provides a ranked list of acceptable choices, where each choice says both:

- which good they want, and
- how many copies of that good they want.

The model assigns **exactly one acceptable choice** to each person. It must respect the available stock, and it looks for an assignment that is **stable** in the sense that no two people can reasonably complain by comparing each other’s allocations and swapping would-be improvements.

The optimization goal is to leave unused goods of **high value** whenever possible, which is equivalent to maximizing the total value of the remaining stock.

The stable commodity assignment problem is defined as follows. We have a set of people, `PERSON`,
and a set of goods, `GOOD`. Each person has a ranked list of which `GOOD`s they like and how many
would make them happy. We have a certain amount available of each good.
An correct assignment is that each person is given one type of the goods in their preference list,
and they are given the number they want of that good.
A stable commodity assignment is a correct assignment, where there is no pair of people and
goods such that each person would be happier with swapping the good with the other person,
and we still have enough of each good to do the swap (since the two people may require diﬀerent
amounts of the good).

The aim is to minimize the total value of goods given to the people while still being a stable
assignment.

## Parameters

For each good `g` we are given:

- `available[g]`: how much is available
- `value[g]`: the value of the good

We are given the preferences of all people in one list all together:

- `npref[p]`: defines the number of preferences for person `p`
- `good_pref[i]`: defines the ith good in the preference list.
- `req_pref[i]`: defines the number required of the `i`th good in the list

For example with `PERSON = { A, B, C }` and `npref=[4, 1, 2]` the we can interpret the preference list

`good_pref = [ CAR, HOUSE, BOOKS, CASH, HOUSE, CAR, CASH ];`

`req_pref  = [   1,     1,    20, 2000,     1,   2, 5000 ];`

as person A prefers a 1 car, before 1 house before 20 books, before 2000 cash, person B prefers 1 house only, and person C prefers 2 cars to 5000 cash.


## Decision variables

For each person, the model chooses:

- `preference[p]`: which entry in that person’s preference list is selected,
- `good[p]`: the good assigned to that person,
- `num[p]`: how many copies of that good they receive.

For each good, it also computes:

- `remainder[g]`: how many copies are left unused after all assignments.

## Main constraints

### 1. Pick one acceptable request per person

Each person must receive one of the options from their own preference list. The selected `good` and `num` are derived from that chosen preference.

### 2. Do not exceed supply

For every good type, the total number allocated to all people plus the leftover amount must equal the available stock. This ensures the model never assigns more copies than exist.

### 3. Stability condition

The central constraint compares every pair of people. Informally, it prevents a pair from forming a **blocking situation** where one or both would prefer the other person’s assigned good and quantity, and the swap could be made feasible using the remaining stock.

The implementation uses:

- `rank[p,g]`: where good `g` appears in person `p`’s preference list, and
- `required[p,g]`: how many copies person `p` would need for good `g` if that option is listed.

The pairwise stability test is compact and somewhat subtle. A beginner-friendly reading is: for any two assigned people, at least one reason must exist why exchanging attention to the other person’s good does **not** create a justified objection.

## Objective

The model defines

- `objective = sum(g in GOOD)(remainder[g] * value[g])`

and **maximizes** it.

So the solver prefers solutions that leave behind goods with higher value. The model also prints

- `obj = sum(p in PERSON)(num[p] * value[good[p]])`

which is the total value of the goods actually assigned, but this is **not** the optimized quantity.

## Notes for beginners

- This is a **combinatorial optimization** model.
- Preferences are stored in a flattened format, then helper functions reconstruct each person’s list.
- The model includes an explicit search annotation using `int_search(...)`. Since benchmark descriptions should focus on the problem rather than solver guidance, that search strategy is not part of the conceptual problem statement.

## Identifiable source / references

What can be identified from this repository:

- the benchmark is named **stable-goods**,
- it appears in the MiniZinc benchmark suite,
- `metadata.json` indicates use in the **MiniZinc Challenge 2020**.



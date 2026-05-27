# Fox–Geese–Corn

## Overview

This MiniZinc model describes a generalized river-crossing problem based on the classic fox, goose, and corn puzzle. Instead of moving just one fox, one goose, and one bag of corn, the model allows many items of each type and asks:

- how many foxes, geese, and corn units should be moved on each boat trip,
- how many trips should actually be used,
- and which transport plan gives the highest final value on the destination bank.

The setting has two river banks, which the model tracks as **west** and **east**. Initially, all items start on the west bank. Odd-numbered trips move items from west to east, and even-numbered trips move items back from east to west. This means the model can use return trips when that helps preserve or improve the final outcome.

Every one knows the puzzle of a farmer with a fox, a goose, and a bag of corn to take to the market.
She has to cross the river with a boat that can carry one object, if she ever leaves the fox with the
goose, the goose is eaten, or the goose with the corn the corn is eaten, and she has to get everything
across the river. This is a generalization of that problem.
The farmer has `f` foxes, `g` geese, and `c` bags of corn on the west side of the river. She has a
boat that can carry `k` objects (any mix of types is allowable) and the time to make `t` trips. Note
that the first trip is west to east, then the second trip is east to west, then the third trip is west
to east, etc. When ever the farmer leaves some goods alone on either side of the river then by the
time she returns the following happens,
- if there is only one kind of good, nothing.
- if there are only foxes and corn, out of boredom one fox eats a bag of corn, its stomach
explodes and it dies.
- if there are foxes and geese,
   * if there are more foxes than geese one fox dies in argument over geese, no geese die, and
no geese eat any corn
   * if there are no more foxes than geese, each fox eats a goose, and no geese eat any corn.
- if there are no foxes but there is geese and corn,
   * if there is no more geese than corn each goose eats a bag of corn
   * otherwise all the geese fight, one dies and one bag of corn is eaten.
     
Once she has completed her last trip then the farmer can take the goods from the east side to the
market where she receives `pf` for each fox, `pg` for each goose and `pc` for each corn. The aim is to
maximize profit.


## What the model is solving

The model is not simply trying to move everything across. Instead, it is solving an **optimization** problem: it chooses a transport plan that maximizes the total value of the items that remain safely on the east bank at the end.

This matters because leaving foxes, geese, and corn together without supervision can cause losses. Those interactions are encoded in the predicate `alone(...)`, which updates what remains on a bank after it is left unattended. At a high level, this predicate represents the model's built-in “what gets eaten or lost when left together” rules.

## Parameters

The main input data are:

- `f`, `g`, `c`: the initial numbers of foxes, geese, and corn units.
- `k`: the boat capacity, measured as the maximum total number of items moved on one trip.
- `t`: an upper bound on the number of trips the model may consider.
- `pf`, `pg`, `pc`: the value (or profit) of one fox, one goose, and one corn unit that successfully ends on the east bank.

From these, the model also computes `maxp`, a safe upper bound for the objective value.

## Decision variables

The model makes the following choices:

- `fox[i]`, `geese[i]`, `corn[i]`: how many items of each type are transported on trip `i`.
- `trips`: the number of trips that are actually used, between `0` and `t`.
- `wfox[i]`, `wgeese[i]`, `wcorn[i]`: how many foxes, geese, and corn units are on the west bank after trip `i`.
- `efox[i]`, `egeese[i]`, `ecorn[i]`: how many foxes, geese, and corn units are on the east bank after trip `i`.
- `objective`: the final weighted value of the items on the east bank.

## Main constraints

The model enforces several simple but important rules:

1. **Initial state**  
   At trip `0`, all items are on the west bank and none are on the east bank.

2. **Trip direction**  
   Odd trips send items from west to east. Even trips send items from east back to west.

3. **Bank updates**  
   After each trip, the west-bank and east-bank inventories are updated to reflect what was transported.

4. **Unattended-bank losses**  
   The predicate `alone(...)` determines what survives on the bank that has been left without supervision. This is the key rule that captures the fox/geese/corn interactions described above.

5. **Boat capacity**  
   For every trip, the total number of transported items must satisfy
   $fox[i] + geese[i] + corn[i] \le k$.

6. **Unused trips carry nothing**  
   If `i > trips`, then trip `i` transports zero foxes, zero geese, and zero corn.

## Objective

The model maximizes

$$
objective = efox[trips] \cdot pf + egeese[trips] \cdot pg + ecorn[trips] \cdot pc
$$

So the best solution is the one that leaves the most valuable combination of surviving items on the east bank after the final used trip.

## Notes on interpretation

- This is best understood as a **generalized optimization version** of the classic river-crossing puzzle, not just the usual yes/no feasibility puzzle.
- The exact loss behavior is defined directly by the `alone(...)` predicate. Some of those rules are more detailed than the usual textbook statement of the puzzle, so anyone reusing the model should read that predicate carefully.

## Related background

This model is closely related to the classic river-crossing puzzle often called **fox, goose, and corn** (or similar variants such as **fox, goose, and beans**), where unsafe combinations cannot be left alone on one bank. The present MiniZinc model extends that idea by allowing larger quantities, return trips, and an explicit value-maximization objective.

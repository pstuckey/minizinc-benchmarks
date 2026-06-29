# Valve Network (MiniZinc) 

The advent of code 2022 problem 16 text is given below

> Day 16: Proboscidea Volcanium 
The sensors have led you to the origin of the distress signal: yet another handheld device, just like the one the Elves gave you. However, you don't see any Elves around; instead, the device is surrounded by elephants! They must have gotten lost in these tunnels, and one of the elephants apparently figured out how to turn on the distress signal.

> The ground rumbles again, much stronger this time. What kind of cave is this, exactly? You scan the cave with your handheld device; it reports mostly igneous rock, some ash, pockets of pressurized gas, magma... this isn't just a cave, it's a volcano!

> You need to get the elephants out of here, quickly. Your device estimates that you have 30 minutes before the volcano erupts, so you don't have time to go back out the way you came in.

> You scan the cave for other options and discover a network of pipes and pressure-release valves. You aren't sure how such a system got into a volcano, but you don't have time to complain; your device produces a report (your puzzle input) of each valve's flow rate if it were opened (in pressure per minute) and the tunnels you could use to move between the valves.

> There's even a valve in the room you and the elephants are currently standing in labeled AA. You estimate it will take you one minute to open a single valve and one minute to follow any tunnel from one valve to another. What is the most pressure you could release?

> For example, suppose you had the following scan output:

- Valve AA has flow rate=0; tunnels lead to valves DD, II, BB
- Valve BB has flow rate=13; tunnels lead to valves CC, AA
- Valve CC has flow rate=2; tunnels lead to valves DD, BB
- Valve DD has flow rate=20; tunnels lead to valves CC, AA, EE
- Valve EE has flow rate=3; tunnels lead to valves FF, DD
- Valve FF has flow rate=0; tunnels lead to valves EE, GG
- Valve GG has flow rate=0; tunnels lead to valves FF, HH
- Valve HH has flow rate=22; tunnel leads to valve GG
- Valve II has flow rate=0; tunnels lead to valves AA, JJ
- Valve JJ has flow rate=21; tunnel leads to valve II

> All of the valves begin closed. You start at valve AA, but it must be damaged or jammed or something: its flow rate is 0, so there's no point in opening it. However, you could spend one minute moving to valve BB and another minute opening it; doing so would release pressure during the remaining 28 minutes at a flow rate of 13, a total eventual pressure release of 28 * 13 = 364. Then, you could spend your third minute moving to valve CC and your fourth minute opening it, providing an additional 26 minutes of eventual pressure release at a flow rate of 2, or 52 total pressure released by valve CC.

> Making your way through the tunnels like this, you could probably open many or all of the valves by the time 30 minutes have elapsed. However, you need to release as much pressure as possible, so you'll need to be methodical.
Work out the steps to release the most pressure in 30 minutes. What is the most pressure you can release?

The original problem had only one agent **Me** the version of this model adds a new agent **Elephant**.


## What problem is this model solving?
This model plans how to operate a network of valves over a limited number of minutes.

- Each valve (node) has a **flow rate**.
- Two agents (**Me** and **Elephant**) move through the network.
- At each minute, each agent can either move to a connected node or open the valve at their current node.
- Open valves contribute flow in every minute after they are opened.

The goal is to choose actions over time so the total released flow is as large as possible.

---

## Inputs (data)
The model uses these key inputs:

- `Nodes`: the set of valve locations.
- `first_node`: where both agents start.
- `flow[node]`: flow rate of each valve.
- `connections[node]`: which nodes can be reached in one move.
- `horizon`: number of minutes in the plan.

In this file, the network and flow values are embedded directly in the model (instead of a separate `.dzn` file), and hardness is adjusted using `horizon`.

---

## Decision variables (what the solver chooses)
- `position[minute, person]`: where each agent is at each minute.
- `action[step, person]`: action at each step (`Move` or `Open`).
- `open[node, minute]`: whether a valve is open at each minute.

Derived quantity:
- `current_flow[minute]`: sum of flow rates of all valves open at that minute.
- `checksum`: total flow over all minutes, i.e. `sum(current_flow)`.

---

## Main constraints (rules)
1. **Initial state**
   - Both agents start at `first_node`.
   - All valves are initially closed.

2. **Action effects**
   - If an agent chooses `Open`, the valve at that agent’s current position becomes open.
   - If an agent chooses `Move`, they must move to one of the connected nodes.

3. **State progression over time**
   - Valve open/closed states are carried forward minute to minute, except where opening occurs.
   - A valve remains open once opened (the update rules enforce persistence).

4. **Two-agent interaction handling**
   - Combined constraints ensure both agents’ actions at a step are reflected consistently in the valve state.

---

## Objective
The model **maximizes**:

- `checksum = sum(minute in Minutes)(current_flow[minute])`

So it prefers plans that open high-flow valves early and keep them open for more minutes.

---

## Output
For each minute, it prints:
- positions of `Me` and `Elephant`,
- set of currently open valves,
- final `checksum` value.

---

## Notes on uncertainty / modeling assumptions
- The model includes the network directly in the `.mzn`; this is convenient but less reusable than a separate data file.
- Time indexing is compact (`Minutes` and `Steps`) and can be subtle for beginners; interpretation is “state tracked per minute, actions per step.”
- The intent appears to follow Advent of Code 2022 Day 16 (two-agent variant), but exact puzzle semantics (e.g., minute-by-minute timing conventions) may differ slightly depending on interpretation.
- Some constraints are written in a nontrivial way to combine both agents’ effects; equivalent formulations are possible.

---

## References
- Advent of Code 2022, Day 16: https://adventofcode.com/2022/day/16
- Commented source reference in model: https://github.com/zayenz/advent-of-code-2022
- Model author (from file header): Mikael Zayenz Lagerkvist

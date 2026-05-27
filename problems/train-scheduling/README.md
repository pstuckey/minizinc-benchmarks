# Train Scheduling (MiniZinc) — Beginner Guide

## What problem is this model solving?
This model builds a feasible timetable for multiple train services moving through a rail network.

For each service, it decides when the train arrives and departs at each stop, whether it stops at ordinary stations, and which engine is used. At the same time, it enforces practical railway limits such as platform capacity, travel times, and spacing between trains on shared track segments.

The model balances two goals:
1. Keep trains close to their preferred finishing times.
2. Avoid skipping stations that have a penalty.

The aim is to build a detailed train timetable from a list of routes and services.
The rail network is made up of `STOP`s. It includes a dummy stop `dstop` which does actually
exist to pad arrays. Each stop has a minimal wait time to let passengers get on and off. Each
stop has a `skip_cost` which is the cost if we skip the station in order to run the service faster
(i.e. wait less than the minimal wait time). Each stop has a number of platforms available. Each
stop is either an ordinary station, a hub station where many lines meet, or a terminus station
where services can begin and end. There is a travel time matrix which records the travel time
between two directly connected stops, or has absent `<>` if they are not connected. Each directly
connected pairs of stops have a line type for the line connecting them: `SING`, a single track for
both directions (so we need to have one train leave the connection before we can start a train in
the opposite direction, and trains going the same direction cannot pass); `DOUB`, a single track for
each of the two directions between the stops (so trains going the same directions cannot pass, but
the two directions are independent); `QUAD`, two lines in each direction allowing arbitrary train
passing in both directions; or `NONE`, there is no direct connection between the stops. There is a
minimum separation min sep (in terms of time units) between two services taking the same link
from STOP to STOP in the same direction, if the connection is `SING` or `DOUB`.



---

## Main inputs (data you provide)
- **Stops and network**: stations (`STOP`), travel times, line type between stations (`SING`, `DOUB`, `QUAD`, `NONE`), platform counts.
- **Station rules**: minimum wait at each stop, station type (`ORDINARY`, `HUB`, `TERMINUS`), skip penalty.
- **Routes and services**: predefined routes, route lengths, service-to-route mapping, desired start/end times.
- **Engines**: available engines and their start locations.
- **Timing horizon**: `makespan` and minimum separation `min_sep`.

The model also contains many assertions to validate data consistency (for example, symmetric line types, non-negative waits/costs, and valid dummy-stop behavior).

---

## Decision variables (what the solver chooses)
- `arrive[s,n]`: arrival time of service `s` at route position `n`.
- `depart[s,n]`: departure time of service `s` at route position `n`.
- `wait[s,n]`: dwell time (`depart - arrive`).
- `stopped[s,n]`: whether service `s` actually stops at that position.
- `engine[s]`: engine assigned to service `s`.
- `prev[s]`: predecessor of service `s` (either another service or an engine start).
- `delay_obj`, `skip_obj`: objective components.

---

## Core constraints (high level)
- **Time flow along a route**: next arrival must be after previous departure + travel time.
- **Minimum waiting**: if a train stops, dwell time must meet station minimum.
- **Platform capacity**: number of trains waiting at a station cannot exceed platform count (`cumulative`).
- **Mandatory stops**: non-ordinary stations must be served.
- **Engine continuity**: service chains must be consistent in location and time; every predecessor is unique (`alldifferent(prev)`).
- **Track safety/separation**:
  - Double-track sections enforce directional separation.
  - Single-track sections enforce ordering between opposite directions.

The schedule constraints are:
- No service starts (arrives) at its first station before it service start time.
- The wait time at each stop is the depart time minus the arrive time
- The wait time at each stop is greater than or equal to the minimal wait time if the service
stopped at the stop
- The arrival time at the next stop is at least the travel time from the previous stop to this one
plus the departure time of the previous stop
- For dummy stops the arrival time is the departure time from the previous stop, the wait time
is 0 and the departure time is the arrival time. This means all these times duplicate the real
end time of the service.

Each stop only has a limited number of platforms. We need to
ensure that no more than `platform[st]` trains are ever waiting at stop `st`. A train is at the stop
from its arrival time to its departure time.

Now we need to assign engines to each service, and assign a previous “service” to each service. The
`prev` variables are the key decisions here:
- If `prev[s] = e(e)` then this means service `s` is the first to use the engine `e`. The start station
for this service and the engine should be the same.
- If `prev[s] = s(s′)` then this means service `s` follows service `s′` using the same engine. The
first stop for service `s′` should be the last stop for service `s`, and the start time for service `s′`
should be no earlier than the end time of service `s`, and the engines used by `s` and `s′` should
be the same.
Clearly two services cant have the same previous “service”.

A double track between stop `st1` to `st2` is two single tracks, one for each direction. This means while
trains going in different directions are independent, trains going the same direction are constrained,
by minimum separations constraints and cant pass. We need to constrain each pair of services `s1`
and `s2` on a double track which move from stop `st1` to `st2` that
- Either service `s1` departs station `st1` at least `min_dep` minutes after `s2`, or vice versa.
- If service `s1` departs `st1` before `s2` then it arrives at `st2` at least `min_sep` minutes before `s2`,
and vice versa (if `s2` departs first, then it arrives first).

A single track between stop `st1` to `st2` means we cant have two trains going in different directions
on the track segment. Add a constraint for each pair of services `s1` and `s2` on a single track segment
which move from stop `st1` to `st2` or stop `st2` to `st1` that
- If they both move from `st1` to `st2` then there is a `min_dep` difference in departure times, and
a `min_dep` difference in arrival times, and they maintain the same order.
- If they move in opposite directions then `s1` finishes using the segment before `s2` starts using
the segment or vice versa

We are only allowed to skip ORDINARY stations. We still must enforce that all the HUB and
TERMINUS stations are stopped at for each service.

---

## Objective
Yes, this model has an objective. It minimizes:

\[
\texttt{objective} = \texttt{delay\_obj} + \texttt{skip\_obj}
\]

Where:
- `delay_obj` is total absolute deviation from each service’s ideal end time.
- `skip_obj` is total penalty for skipped stops.



The delay objective tries to finish each service at the service end time. A service ends at its
depart time from the last stop in the route. Calculate the `delay_obj` as the sum over all the services
of the difference from the end of the service to its preferred service end time.

The skip objective pays a penalty for each stop that is skipped in a service. The `n`th stop of
service `s` if skipped if `stopped[s,n]` is set false. Note that if a service skips a stop the wait time
for that service can be less than the minimal wait time of the stop. We pay a skip cost equal to
the skip cost for that stop for each service that skips it. Calculate `skip_obj` as the sum of all skip
costs.

The model minimizes the sum of `delay_obj` and `skip_obj`

---

## Notes on uncertainty
- The model is clear about operational constraints, but intended real-world assumptions (for example, whether `QUAD` lines should have additional special rules) are not documented in comments.
- The predecessor variable `prev` is constrained for engine chaining, but there is no explicit narrative in the model explaining all intended dispatch policies.
- Data semantics (units for time, exact interpretation of service end preference) are inferred from variable names and constraints.

---

## Identifiable references
- Primary source: model file `trains.mzn` in this folder.
- Related benchmark metadata: `metadata.json` (MiniZinc Challenge 2024 instances listed).
- A related repository README (in `problems/train-scheduling/README.md`) mentions “Musliu et al., Train Scheduling and Timetabling Problems,” but this citation is not verified inside `trains.mzn` itself.

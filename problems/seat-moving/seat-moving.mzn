%------------------------------------------------------------------------------%
% Seat Moving -
% MiniZinc Challenge 2018 Problem Submission
%
% Submitter: Toshimitsu Fujiwara
%
% Move person sitting at start position to goal position.
%  Person can empty seat as temporary space.
%  Some person can be swapped directly. (for an instance, having small luggage)
%
% Modified by MiniZinc team:
%   - Beautification of code
%   - Adjustments of the output item
%
% Peter Stuckey June 2026:  Made it more type safe
%------------------------------------------------------------------------------%
% Includes

include "alldifferent_except.mzn";
include "alldifferent.mzn";

%------------------------------------------------------------------------------%
% Parameters and Variables

% number of seats
int: S;
set of int: SEAT = 1..S;

% number of person
int: P;
enum PERSONX = {EMPTY} ++ p(1..P);
set of PERSONX: PERSON = p(1..P);
% flags
array[PERSON] of bool: Can_swap;

% max step.
% (keep small to keep search space small)
int: MAX_STEP = (2 * S) div (S - P + 1) + 1;
set of int: TIME = 1..MAX_STEP;
set of int: TIME0 = 0..MAX_STEP;
% int: MAX_STEP = (2 * S);

% move cost
var 0..P * MAX_STEP: cost;

% step
var TIME0: step;

% objective = step * ub(cost) + cost
var 0..MAX_STEP * MAX_STEP * P + MAX_STEP * P : objective;

% state of start and goal
array[SEAT] of int: Start;
array[SEAT] of int: Goal;

array[SEAT] of PERSONX: StartT = [ if Start[s] = 0 then EMPTY else p(Start[s]) endif | s in SEAT ];
array[SEAT] of PERSONX: GoalT = [ if Goal[s] = 0 then EMPTY else p(Goal[s]) endif | s in SEAT ];

% seat[i, s] means "Who is at s in step i"
% EMPTY means "empty seat"
array[TIME, SEAT] of var PERSONX: seat;

% person[i, p] means persion "p" is at "person[i, p]" in step i
array[TIME, PERSON] of var SEAT: person;


%------------------------------------------------------------------------------%
% Constraints

%
% bind initial and last seating
%
constraint
	forall(i in SEAT) (
		 seat[1, i] = StartT[i]
		 /\ seat[MAX_STEP, i] = GoalT[i]
	);

%
% bind person and seat
%
constraint
	forall(i in TIME) (
		forall(p in PERSON) (
			seat[i, person[i, p]] = p
		)
	);

% person don't appear twice
constraint
	forall(i in TIME) (
		alldifferent_except(seat[i, ..], {EMPTY})
	);

constraint redundant_constraint(
	forall(i in TIME) (
		alldifferent(person[i, ..])
	)
);

%
% objective
%
constraint objective = step * P * MAX_STEP + cost;

%
% cost
%
constraint cost = sum([ 
    sum(
        [ person[i, p] != person[i + 1, p] 
        | p in PERSON]
    ) 
| i in 1..MAX_STEP - 1
]);


% Don't move after all seats are fixed.
constraint
	forall(i in 1..MAX_STEP) (
		step < i -> forall(s in SEAT) (seat[i, s] = GoalT[s])
	);

%
% moving constraint
%
% allowed moves:
%   * person having small equipments (Can_swap = 1) and swap two seats
%   * move to empty seat
%
constraint
	forall(i in 1..MAX_STEP - 1, p in PERSON) (
	    person[i, p] != person[i + 1, p] -> (
         (Can_swap[p] /\ person[i, p] = person[i + 1, seat[i, person[i + 1, p]]])
	        \/  seat[i, person[i + 1, p]] = EMPTY 
        )
	);

%------------------------------------------------------------------------------%
% Solve item and search

solve 
    :: seq_search([
        int_search(array1d(person), first_fail, indomain_min, complete),
        int_search(array1d(seat), first_fail, indomain_min, complete),
	    int_search([step], first_fail, indomain_split, complete),
	    int_search([cost], first_fail, indomain_split, complete),
	    int_search([objective], first_fail, indomain_min, complete),
    ])
    minimize objective;

%------------------------------------------------------------------------------%
% Output item

output [
    "seat = array2d(1..\(MAX_STEP), 1..\(S), \(seat));\n",
    "step = \(step);\n",
    "cost = \(cost);\n",
    "objective = \(objective);\n"
];

%------------------------------------------------------------------------------%

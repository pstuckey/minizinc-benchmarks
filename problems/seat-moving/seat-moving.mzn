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
%------------------------------------------------------------------------------%
% Includes

include "all_different_except.mzn";
include "alldifferent.mzn";

%------------------------------------------------------------------------------%
% Parameters and Variables

% number of seats
int: S;
enum SEAT = Seat(1..S);

% number of person
int: P;
enum PERSON = Person(1..P) ++ { Noone };


% flags
array[1..P] of bool: Can_swap;
array[PERSON] of bool: Can_swapT = array1d(PERSON, Can_swap ++ [ false ]);

% max step.
% (keep small to keep search space small)
int: MAX_STEP = (2 * S) div (S - P + 1) + 1;
set of int: STEP = 1..MAX_STEP;
% int: MAX_STEP = (2 * S);

% move cost
var 0..P * MAX_STEP: cost;

% step
var 0..MAX_STEP: step;

% objective = step * ub(cost) + cost
var 0..MAX_STEP * MAX_STEP * P + MAX_STEP * P : objective;

% state of start and goal
array[SEAT] of int: Start;
array[SEAT] of int: Goal;

array[SEAT] of PERSON: StartT = [ if Start[s] = 0 then Noone else Person(Start[s]) endif | s in SEAT ];
array[SEAT] of PERSON: GoalT =  [ if Goal[s] = 0 then Noone else Person(Goal[s]) endif | s in SEAT ];


% seat[i, s] means "Who is at s in step i"
% 0 means "empty seat"
array[STEP, SEAT] of var PERSON: seat;

% person[i, p] means persion "p" is at "person[i, p]" in step i. The Noone is meaningless
array[STEP, PERSON] of var SEAT: person;

%------------------------------------------------------------------------------%
% Constraints

%
% bind initial and last seating
%
constraint seat[1,..] = StartT /\ seat[MAX_STEP,..] = GoalT;

%
% bind person and seat
%
constraint
	forall(i in STEP) (
		forall(p in Person(1..P)) (
			seat[i, person[i, p]] = p
		)
	);

% person don't appear twice
constraint
	forall(i in STEP) (
		all_different_except(seat[i, ..], {Noone})
	);

constraint redundant_constraint(
	forall(i in STEP) (
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
constraint cost = sum(i in 1..MAX_STEP-1, p in Person(1..P))(person[i,p] != person[i+1,p]); 


% Don't move after all seats are fixed.
constraint forall(i in STEP) (step < i -> seat[i, ..] = GoalT);

%
% moving constraint
%
% allowed moves:
%   * person having small equipments (Can_swap = 1) and swap two seats
%   * move to empty seat
%
constraint
	forall(i in 1..MAX_STEP - 1, p in Person(1..P)) (
	    person[i, p] != person[i + 1, p] -> (
                (Can_swapT[p] /\ person[i, p] = person[i + 1, seat[i, person[i + 1, p]]])
	        \/  seat[i, person[i + 1, p]] = Noone
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


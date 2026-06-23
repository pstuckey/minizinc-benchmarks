%------------------------------------------------------------------------------%
% trucking.mzn
% Jakob Puchinger
% December 2007
% vim: ft=zinc ts=4 sw=4 et tw=0
% 
% There are N Trucks which have to can be used in every time period,
% Each truck can transport a given Load of material.
% Each truck has an associated cost.
% In each time period a demand has to be fulfilled.
% Truck1 and Truck2 have some further constraints, disallowing
% them to be used more than once in consecutive or two consecutive time periods.
% The goal is to minimise the cost
% Uodated June 2026 Peter Stuckey
%------------------------------------------------------------------------------%

    % Time Periods
int: T;
set of int: TIME = 1..T;
    % Trucks
int: N;
enum TRUCK = Truck(1..N);

1..N: Truck1;
1..N: Truck2;
TRUCK: TRUCK1 = Truck(Truck1);
TRUCK: TRUCK2 = Truck(Truck2);

array[TIME] of int: Demand;
array[TRUCK] of int: Cost;
array[TRUCK] of int: Loads;

array[TRUCK, TIME] of var bool: x;

constraint
    forall(t in TIME)(
        sum(i in TRUCK)( Loads[i] * x[i,t]) >= Demand[t] 
    );

constraint % Truck1 can only be used once in each three consec times
    forall(tau in 1..T-2)(
        sum(t in tau..tau+2)( x[TRUCK1, t] ) <= 1
    );

constraint % Truck2 can only be used once in each two consec times
    forall(tau in 1..T-1)(
        sum(t in tau..tau+1)( x[TRUCK2, t] ) <= 1
    );

solve :: bool_search( [ x[i,t] | i in TRUCK, t in TIME ], smallest, indomain_min)
minimize total_cost;

var int: total_cost;
constraint
    total_cost = sum(i in TRUCK)(sum(t in TIME)( Cost[i] * x[i,t] ));

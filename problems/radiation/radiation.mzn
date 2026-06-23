%-----------------------------------------------------------------------------%
% Radiation problem, MiniZinc 2.0.4 version
%
% Revised by Peter Stuckey June 2026
%
% Model from 
% D. Baatar, N. Boland, S. Brand, and P. J. Stuckey. 
% CP and IP approaches to cancer radiotherary delivery optimization. 
% Constraints, 16(2):173-194, 2011.
%-----------------------------------------------------------------------------%

%-----------------------------------------------------------------------------%
% Parameters
%-----------------------------------------------------------------------------%

int: m;  % Rows
int: n;  % Columns
enum ROW = R(1..m);
enum COL = C(1..m);

	% Intensity matrix
array[ROW, COL] of int: Intensity;


set of int: BTimes = 1..Bt_max;

int: Bt_max   = max(Intensity);
int: Ints_sum = sum(Intensity);

%-----------------------------------------------------------------------------%
% Variables
%-----------------------------------------------------------------------------%

	% Total beam-on time
var 0..Ints_sum: Beamtime;

	% Number of shape matrices
var 0..m*n: K;

	% N[b] is the number of shape matrices with associated beam-on time b
array[BTimes] of var 0..m*n: N;

	% Q[i,j,b] is the number of shape matrices with associated beam-on time
	% b that expose cell (i,j)
array[ROW, COL, BTimes] of var 0..m*n: Q;

%-----------------------------------------------------------------------------%
% Constraints
%-----------------------------------------------------------------------------%

	% For FD/LP hybrid solving, all these should go the LP solver
	% (with a suitable linearisation of the 'max' expressions).
constraint
	Beamtime = sum(b in BTimes) (b * N[b])
	/\
	K = sum(N)
	/\
	forall(i in ROW, j in COL)
		( Intensity[i,j] = sum([b * Q[i,j,b] | b in BTimes]) )
	/\
	forall(i in ROW, b in BTimes)
		( upper_bound_on_increments(N[b], [ Q[i,j,b] | j in COL]) );


predicate upper_bound_on_increments(var int: N_b, array[int] of var int: L) =
	N_b >= L[1] + sum([ max(L[j] - L[j-1], 0) | j in 2..n ]);
	%
	% Good linear version:
	% let { array[min(index_set(L))..max(index_set(L))] of var int: S } in
	% N_b >= L[1] + sum([ S[j] | j in 2..n ]) /\
	% forall([ S[j] >= L[j] - L[j-1] /\ S[j] >= 0 | j in 2..n ]);
	

%-----------------------------------------------------------------------------%
% Objective
%-----------------------------------------------------------------------------%
int: obj_min = lb((m*n + 1) * Beamtime + K);
int: obj_max = ub((m*n + 1) * Beamtime + K);
var obj_min..obj_max: objective = (m*n + 1) * Beamtime + K;

solve 
    :: int_search(
		[Beamtime] ++ N ++
	    	[Q[i,j,b] | i in ROW, j in COL, b in BTimes ],
		input_order, indomain_split, complete)
	minimize objective;
		% really: (Beamtime, K),  i.e. in lexicographic order

%-----------------------------------------------------------------------------%
%-----------------------------------------------------------------------------%

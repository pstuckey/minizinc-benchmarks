%------------------------------------------------------------------------------%
% Constrained Community Detection Problem
%
% The problem is to find communities in the graph with maximum modularity value 
% satisfying must-link and cannot-link constraints which indicate whether a 
% pair of vertices must assign to same or different communities.
%
% Adapted from original community-detection problem used in 2017.
%------------------------------------------------------------------------------%
% Includes

include "globals.mzn";

%------------------------------------------------------------------------------%
% Input and Derived Parameters

array [int, int] of 0..1: A; % Adjacency matrix
constraint assert(
    index_set_1of2(A) = index_set_2of2(A),
    "Invalid adjacency matrix"
);
int: N = card(index_set_1of2(A));
enum NODE = V(1..N);
% well typed data
array[NODE,NODE] of int: AN = [ (V(i),V(j)): A[i,j] | i,j in 1..N ];

int: max_communities; % Max number of communities
enum COMMUNITY = C(1..max_communities);

% Pairs of nodes which must be in the same community
array [int, 1..2] of int: same_community;
enum SAME = S(index_set_1of2(same_community));
array[SAME] of tuple(NODE,NODE): t_same = 
     [ S(i): ( V(same_community[i,1]), V(same_community[i,2]) ) 
     | i in index_set_1of2(same_community) ];

% Pairs of nodes which must not be in the same community
array [int, 1..2] of int: diff_community;
enum DIFF = D(index_set_1of2(diff_community));
array[DIFF] of tuple(NODE,NODE): t_diff = 
     [ D(i): (V(diff_community[i,1]),V(diff_community[i,2]))  
     | i in index_set_1of2(diff_community)];

int: l = sum (AN); % Number of stubs
array [NODE] of int: k = [sum (j in NODE) (AN[i, j]) | i in NODE]; % Node degrees

% Modularity matrix (multiplied by l so no fractions)
array [NODE, NODE] of int: B = array2d(NODE, NODE, [l * AN[i, j] - k[i] * k[j] | i, j in NODE]);

% Objective bounds (compiler should be able to tighten using same/diff_community)
int: obj_lb = sum (i, j in NODE where i < j /\ B[i, j] < 0) (B[i, j]);
int: obj_ub = sum (i, j in NODE where i < j /\ B[i, j] > 0) (B[i, j]);

%------------------------------------------------------------------------------%
% Variables

array [NODE] of var COMMUNITY: x :: add_to_output;

var obj_lb..obj_ub: objective = sum (i, j in NODE where i < j /\ x[i] = x[j]) (B[i, j]);

%------------------------------------------------------------------------------%
% Constraints

constraint symmetry_breaking_constraint(seq_precede_chain(x));

constraint forall (s in t_same) (x[s.1]  = x[s.2]);
constraint forall (d in t_diff) (x[d.1] != x[d.2]);

constraint global_cardinality_low_up(
    x, 
    [c | c in COMMUNITY],
    [0 | c in COMMUNITY],
    [N | c in COMMUNITY]
);

%------------------------------------------------------------------------------%
% Solve item and search

solve :: int_search(x, input_order, indomain_min, complete) maximize objective;

% Use to output actual modularity value
% float: modularity :: output_only :: add_to_output = (2 * fix(objective) + sum (i in NODE) (B[i, i])) / l / l;

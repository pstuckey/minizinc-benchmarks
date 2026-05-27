% Adapted from https://github.com/Kurorororo/didp-models/blob/main/graph-clear/graph_clear_cp.py
% model improvements by Peter Stuckey
% added comments
% separated NODE and TIME for type safety
% improved calculation of sweep costs
% improved calculation of var_l and var_u

include "globals.mzn";

int: n;

enum NODE = Node(1..n);
enum TIME = Time(1..n);

% weight of each node: number of resources to clear
array [NODE] of int: node_weights;
% weight of each edge: number of resources to hold blocked
array [NODE, NODE] of int: edge_weights;

int: m = count (i, j in NODE) (edge_weights[i, j] > 0);
enum EDGE = Edge(1..m);
any: edges = array1d(EDGE, [(i, j) | i, j in NODE where edge_weights[i, j] > 0]);

int: z_lb = 1;
int: c_block = sum(edge_weights);
int: z_ub = max(node_weights) + c_block;
% The sweep cost for node i
array[NODE] of int: sweep_cost = [ node_weights[i] + sum (j in NODE) (edge_weights[i, j] + edge_weights[j, i]) | i in NODE ];
int: c_sweep = max(sweep_cost); 

% for each node, the time when it is cleared (as a node)
array [NODE] of var TIME: var_t;
% The first time a node attched to edge e is cleared
array [EDGE] of var TIME: var_l;
% The second time a node attached to edge e is cleared
array [EDGE] of var TIME: var_u;
% The sweep cost incurred at time t
array [TIME] of var 1..c_sweep: var_s;
% The blocking cost incurred at time t
array [TIME] of var 0..c_block: var_b;
% True if edge e must be blocked at time t
array [EDGE, TIME] of var bool: var_i;
% objective maximum combined cost over time
var z_lb..z_ub: var_z;

var int: objective = var_z;
solve :: int_search(var_t, smallest, indomain_min) minimize objective;

constraint var_z = max (t in TIME) (var_s[t] + var_b[t]);


% set the sweep cost at time t
constraint forall (i in NODE) (
    var_s[var_t[i]] = sweep_cost[i]
);
% the time for each sweep is different
constraint all_different(var_t);
% set the first and last time for each edge, and the time when it must be blocked
constraint forall (e in EDGE, edge = edges[e], i = edge.1, j = edge.2) (
  var_l[e] = min(var_t[i],var_t[j]) /\
  var_u[e] = max(var_t[i],var_t[j]) /\
  forall (t in TIME) (var_i[e,t] = (var_l[e] < t /\ var_u[e] > t))
);
% compute the blocking cost for time t
constraint forall (t in TIME) (
  var_b[t] = sum(e in EDGE, edge = edges[e], i = edge.1, j = edge.2) (edge_weights[i, j] * var_i[e, t])
);

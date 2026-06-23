%------------------------------------------------------------------------------%
% sp_benchmark.mzn
% Jakob Puchinger <jakobp@cs.mu.oz.au>
% June 2008
% vim: ft=zinc ts=4 sw=4 et tw=0
%
% Shortest Path Problem. (by flow)
% 
% updated by Peter Stuckey June 2026
%------------------------------------------------------------------------------%

    % Number of nodes
int: N;
    % Start node
1..N: Start;
    % End node
1..N: End;
enum NODE = V(1..N);
NODE: StartN = V(Start);
NODE: EndN = V(End);


    % Number of edges (directed arcs)
int: M;
    %  The actual edges
enum EDGE = E(1..M);    
    % Edge lengths
array[EDGE] of int: L;
    % Edge start node
array[EDGE] of 1..N: Edge_Start;
array[EDGE] of 1..N: Edge_End;
array[EDGE] of NODE: ES = [ V(Edge_Start[i]) | i in EDGE ];
array[EDGE] of NODE: EE = [ V(Edge_End[i]) | i in EDGE ];


    % Variable indicating if edge is used
array[EDGE] of var bool: x;

constraint
    forall( i in NODE ) (
        if i = StartN then
                % outgoing flow
            sum(e in EDGE where ES[e] = i)(x[e]) - 
                % incoming flow
            sum(e in EDGE where EE[e] = i)(x[e])
            = 1
        elseif i = EndN then
            sum(e in EDGE where ES[e] = i)(x[e]) - 
            sum(e in EDGE where EE[e] = i)(x[e])
            = -1
        else
            sum(e in EDGE where ES[e] = i)(x[e]) - 
            sum(e in EDGE where EE[e] = i)(x[e])
            = 0
        endif
    );

var int: path_length = sum(e in EDGE)( L[e] * x[e] );
solve :: bool_search(x, input_order, indomain_min) minimize path_length;


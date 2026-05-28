
int: X;
int: Y;
set of int: ROW = 1..Y;
set of int: COL = 1..X;

int: maxlen;
array [ROW,1..maxlen] of int: rows;  % clues for rows
array [COL,1..maxlen] of int: cols;  % clues for columns

% decisions variables
enum CELL = { B, F }; % Blank or Filled
array[ROW, COL] of var CELL: A;

include "regular.mzn";

%% Build an automata for a nonogram sequence. using the usual representation, e.g. 2, 2, 3
function array[int] of int: dfa(array[int] of int: pattern) = 
         let { int: states = sum(pattern) + length(pattern);
               array[1..2*states] of 0..states: transition = 
                    [ if exists(i in 0..length(pattern)-1)(s = sum(pattern[1..i]) + i + 1) then
                         % at the state s looking for the start of the ith+1 pattern
                         if c = B then s else s+1 endif
                      elseif s = states then % last state
                         if c = B then s else 0 endif   
                      elseif exists(i in 1..length(pattern))(s = sum(pattern[1..i]) + i) then
                         % have reaches the end of the ith pattern 
                         if c = B then s+1 else 0 endif
                      else
                         if c = B then 0 else s+1 endif
                      endif 
                    | s in 1..states, c in CELL ];
              } in
         transition;
 
%% Build an automata for a nonogram sequence. using the data representation, e.g. 1,1,0,1,1,0,1,1,1       
function array[int] of int: dfao(array[int] of int: pattern) = 
         let { int: states = length(pattern) + 1;
               array[1..2*states] of 0..states: transition = 
                    [ if s = 1 \/ pattern[s] = 1 /\ pattern[s-1] = 0 then
                         % at the state s looking for the start of the ith+1 pattern
                         if c = B then s else s+1 endif
                      elseif s = states then % last state
                         if c = B then s else 0 endif   
                      elseif pattern[s] = 0 /\ pattern[s-1] = 1 then
                         % have reaches the end of the ith pattern 
                         if c = B then s+1 else 0 endif
                      else
                         if c = B then 0 else s+1 endif
                      endif 
                    | s in 1..states, c in CELL ];
              } in
         transition;

% set up a regular constraint for each row
constraint forall(r in ROW)
                 ( let { 
                         array[int] of int: clue = [ rows[r,i] | i in 1..maxlen where rows[r,i] >= 0];
                         array[int] of int: t = dfao(clue);
                         int: states = length(t) div 2;
                         array[1..states,1..2] of int: auto = array2d(1..states,1..2,t);
                         set of int: F = { states };
                   } in
                   regular(A[r,..], states, 2, auto, 1, F)
                  );      
% set up a regular constraint for each col
constraint forall(c in COL)
                 ( let { 
                         array[int] of int: clue = [ cols[c,i] | i in 1..maxlen where cols[c,i] >= 0];
                         array[int] of int: t = dfao(clue);
                         int: states = length(t) div 2;
                         array[1..states,1..2] of int: auto = array2d(1..states,1..2,t);
                         set of int: F = { states };
                   } in
                   regular(A[..,c], states, 2, auto, 1, F)
                  );      

solve :: int_search(array1d(A),input_order,indomain_max,complete) satisfy;

output [
    if fix(A[r, c]) = B then " " else "#" endif ++ 
    if c = Y then "\n" else " " endif
    | r in 1..X, c in 1..Y
];

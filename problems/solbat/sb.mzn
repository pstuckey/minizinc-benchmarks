% new zinc file SolitaireBattleships.mzn
% At attempt to build a solution entirely within the IDE
% By Peter Stuckey August 2009
% Solitaire Battleships is a puzzle where
% we are given a partially filled in board and the number
% of ships in each row and column and have to fill it with ships

% "Improved" version does not introduce reified set_in
% The revised version does
% rewritten in June 2026 to use enumerated types, and count globals.

int: width;   % height of board (usually 10)
int: height;  % width of board (usually 10)
int: maxship; % maximal length of ship (usually 4)

set of int: ROWS = 1..width;
set of int: COLS = 1..height;
set of int: XROWS = 0..width+1;    % extended rows
set of int: XCOLS = 0..height+1;   % extended cols

%% ship types enumerated type
enum SHIP = S(1..maxship);
SHIP: submarine  = S(1);
SHIP: destroyer = S(2);
SHIP: cruiser = S(3); 
array[SHIP] of int: length = [ S^-1(s) | s in SHIP ];

%% the PIECES enumerated type!
enum PIECE = { W, C, L, R, T, B, M };
%int: w = 1; % water
%int: c = 2; % circle (submarine)
%int: l = 3; % left end of ship
%int: r = 4; % right end of ship
%int: t = 5; % top of ship
%int: b = 6; % bottom of ship
%int: m = 7; % middle of ship
array[PIECE] of string: code = [".","c","l","r","t","b","m"];

array[ROWS,COLS] of 0..7: hint; % the initial board configuration
array[ROWS] of int: rowsum;     % sums for each row
array[COLS] of int: colsum;     % sums for each col
array[SHIP] of int: ship; % the number of each type of ship (usually [4,3,2,1]).

% variables 
array[XROWS,XCOLS] of var PIECE: board;  % the board
 
array[XROWS,XCOLS] of var bool: fill;     % which pieces are ships

array[PIECE] of var 0..width*height: npiece; % number of pieces of each type


% model
include "globals.mzn";

% ensure hints are respected
constraint forall(i in ROWS, j in COLS)(
			   if hint[i,j] > 0 then
			      board[i,j] == to_enum(PIECE,hint[i,j])
			   endif
	       ); 

% make extended rows and cols empty
constraint forall(i in XROWS)(board[i,0] == W /\ board[i,width+1] == W);
constraint forall(j in COLS)(board[0,j] == W /\ board[height+1,j] == W);

% ensure that the fill array matches the board
constraint forall(i in XROWS, j in XCOLS)(
			   fill[i,j] = (board[i,j] != W)
	       ); 

% spacing constraints: gaps betwen ships
constraint forall(i in ROWS, j in COLS)(
	   (board[i,j] == W \/ board[i+1,j+1] == W)
	/\ (board[i,j] == W \/ board[i+1,j-1] == W)   % diagonal constraints
       /\ (board[i,j] in {C,L,R,T} -> board[i-1,j] == W)
       /\ (board[i,j] in {C,L,R,B} -> board[i+1,j] == W)
       /\ (board[i,j] in {C,L,T,B} -> board[i,j-1] == W)
       /\ (board[i,j] in {C,R,T,B} -> board[i,j+1] == W)
           );
               			                       
% ship shape constraints
constraint forall(i in ROWS, j in COLS)(
               %% a left piece needs a right piece or middle to the right
			   (board[i,j] == L -> board[i,j+1] in {R,M})
			/\ (board[i,j] == R -> board[i,j-1] in {L,M})
			/\ (board[i,j] == T -> board[i+1,j] in {B,M})
			/\ (board[i,j] == B -> board[i-1,j] in {T,M})
			   %% a middle piece has to have two opposite sides filled
			/\ (board[i,j] == M -> (   fill[i-1,j] == fill[i+1,j]
			                        /\ fill[i,j-1] == fill[i,j+1]
			                        /\ (fill[i-1,j] xor fill[i,j-1])))
		   );
		   
% sum up pieces
constraint forall(p in PIECE)(
			   npiece[p] = count_eq(board,p)
		   );

% piece sum constraints
constraint npiece[C] == ship[submarine]; % submarines
constraint npiece[L] == npiece[R]; % left right (probably redundant)
constraint npiece[T] == npiece[B]; % top bottom
constraint npiece[L] + npiece[T] == sum(s in destroyer..S(maxship))(ship[s]); 
                                   % no of ends
constraint npiece[M] == sum(s in cruiser..S(maxship))(ship[s] * (length[s] - 2)); 
                                   % no of middles 
% redundant
constraint sum(npiece) = (width+2)*(height+2);                                   		   
		    
% count number of bigger ships
% at least for standard battleships you can probably simply
% enforce this constraint for s in destroyer..destroyer		
% and still be guaranteed a correct solution    
constraint forall(s in destroyer..S(maxship))(
                  let { int: ls = length[s]; } in
	           count(i in ROWS,j in COLS)(
			       if j + ls - 1 <= width then
			          board[i,j] == L /\ board[i,j+ls-1] == R     % ship length s lr
			       /\ forall(k in j+1..j+ls-2)(board[i,k] == M)
			       else false endif
			    \/
			       if i + ls - 1 <= height then
			          board[i,j] == T /\ board[i+ls-1,j] == B     % ship length s tb
			       /\ forall(k in i+1..i+ls-2)(board[k,j] == M)
			       else false endif
		       ) = ship[s]
		   );		    
		    		    

% row sums respected
constraint forall(i in ROWS)(
               count(fill[i,..]) == rowsum[i]
           );
           
% column sums respected           
constraint forall(j in COLS)(
               count(fill[..,j]) == colsum[j]
           );           



solve 
    :: seq_search([
        bool_search([ fill[i,j] | i in ROWS, j in COLS], 
            input_order, indomain_min, complete),
        int_search([ board[i, j] | i in ROWS, j in COLS], 
            first_fail, indomain_min, complete)
    ])
    satisfy;

output [ "% " ] ++ [ 
    code[fix(board[i,j])] ++ 
    if j == width then " " ++ show(rowsum[i]) ++ "\n% "
    else "" endif
| i in ROWS, j in COLS ] ++ [ 
    show(colsum[j]) 
| j in COLS ] ++ [
    "\n"
] ++ [
    "board = array2d(", show(XROWS), ", ", show(XCOLS), ", ", show(board), ");\n"
];


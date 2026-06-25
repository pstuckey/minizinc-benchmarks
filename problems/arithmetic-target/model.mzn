% MIT License

% Copyright (c) 2022 Kelvin Davis

% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:

% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.

% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.
% 
% Revised version by Peter Stuckey June 2026

include "globals.mzn";

array[int] of int: numbers;
int: target;
int: n = length(numbers);
% nodes in the binary tree: NULL = dummy, leafs for each input numbers and 
% internal OP nodes
enum NODE = { NULL } ++ Leaf(1..n) ++ OP(1..n-1);

% Binary Tree
enum TOKEN = {Val, Add, Sub, Mul, Div, Null};

array[NODE] of var TOKEN: tree; % operation, or Val if leaf
array[NODE] of var NODE: left;  % left child
array[NODE] of var NODE: right; % right child
var NODE: root; % root of tree (largest used node)
var 0..n: used = sum(i in Leaf(1..n))(tree[i] != Null);

% the leaf nodes are only used or not, and have no children
constraint forall(i in 1..n)(tree[Leaf(i)] in { Val, Null } /\
                             left[Leaf(i)] = NULL /\
                             right[Leaf(i)] = NULL);
% The NULL node is never used                             
constraint tree[NULL] = Null /\ left[NULL] = NULL /\ right[NULL] = NULL;


% Constrain all items
constraint forall (i in OP(1..n-1)) 
 (tree[i] != Val /\ left[i] < i /\ right[i] < i);
% Constrain unused items
constraint forall (i in NODE where i > root) 
 (tree[i] = Null /\ left[i] = NULL /\ right[i] = NULL);
% Constrain used items
constraint forall (i in 1..n-1 where OP(i) <= root) (is_node(OP(i)));
% node constraint
predicate is_node(var NODE: i) = (
  tree[i] != Val /\ tree[i] != Null /\
  tree[left[i]] != Null /\ tree[right[i]] != Null /\
  left[i] < i /\
  right[i] < i /\
  true
);

% Each node is used at most once in left and right (tree)
constraint global_cardinality(left ++ right, NODE, [0 | i in 1..2*n], [4*n] ++ [ 1 | i in 1..2*n-1 ]);


% value of each node
set of int: VRANGE = 0..10*target;
array[NODE] of var VRANGE: value;
constraint value[NULL] = 0;
% leafs are there own value if used
constraint forall(i in 1..n)
           (value[Leaf(i)] = numbers[i]*(tree[Leaf(i)] = Val));          
           
constraint forall(i in 1..n-1)
           (let { NODE: node = OP(i);
                  array[TOKEN] of var int: v = 
                  [ 0, % Val not possible
                    value[left[node]] + value[right[node]], % Add                    
                    value[left[node]] - value[right[node]], % Sub
                    value[left[node]] * value[right[node]], % Mul
                    safediv(value[left[node]],value[right[node]]), % Div (non-failing)
                    0];  % Null
            } in
            % compute the value of this node
            value[node] = v[tree[node]] /\
            % enforce that division is exact
            if tree[node] = Div then 
               value[left[node]] mod value[right[node]] = 0
            endif         
            );
           
                        
function var int: safediv(var int: x, var int: y) :: promise_total 
         = 
         if y = 0 then 0 else x div y endif;    
                             
                                                                               
var int: objective = 10*abs(value[root] - target) + used;
solve :: seq_search([
           int_search([root], input_order, indomain_min),
           int_search(tree, input_order, indomain_min),
           int_search(left, input_order, indomain_min),
           int_search(right, input_order, indomain_min)])
   minimize objective;


%/**
% * Break Symmetry
% */

% no sub-expression can be negative
% constraint symmetry_breaking_constraint(
%   forall (i in M) (
%     tree_vals[i] >= 0
%   )
% );

% string of additions and subtractions must be associative in one direction
% the values of the string must be in sorted order

% Associativity of Addition: (a+b)+c = a+(b+c)
constraint symmetry_breaking_constraint(
  forall (i in NODE) (
    tree[i] = Add -> tree[left[i]] != Add
  )
);

% Identity of Addition: a = 0+a = a+0
constraint symmetry_breaking_constraint(
  forall (i in NODE) (
    tree[i] = Add -> (value[left[i]] != 0 /\ value[right[i]] != 0)
  )
);
% Associativity of Multiplication: (a*b)*c = a*(b*c)
constraint symmetry_breaking_constraint(
  forall (i in NODE) (
    tree[i] = Mul -> tree[left[i]] != Mul
  )
);
% Identity of Multiplication: a = 1*a = a*1
constraint symmetry_breaking_constraint(
  forall (i in NODE) (
    tree[i] = Mul -> (value[left[i]] != 1 /\ value[right[i]] != 1)
  )
);

% (a-b)-c = a-(b+c)
constraint symmetry_breaking_constraint(
  forall (i in NODE) (
    tree[i] = Sub -> tree[left[i]] != Sub
  )
);

% tree representation symmetry
%% the children of an OP node are left before right if the operator 
%% is commutative unless the right is a leaf and the left not 
constraint symmetry_breaking_constraint(
  forall(i in 1..n-1) (
     let { NODE: node = OP(i); } in
     node > root \/ 
     tree[node] in { Sub, Div } \/
     left[node] < right[node] \/
     (right[node] in Leaf(1..n) /\ left[node] in OP(1..n-1))
  )
);


/*
% Distributivity of Multiplication
% a*(b+c) = a*b + a*c
%         = b*a + a*c
%         = a*b + c*a
%         = b*a + c*a
% a*(b-c) = a*b - a*c
%         = b*a - a*c
%         = a*b - c*a
%         = b*a - c*a
constraint symmetry_breaking_constraint(
  forall (i in M) ((
    (tree[i] = Add \/ tree[i] = Sub) /\
    tree[left[i]] = Mul /\ tree[right[i]] = Mul) -> (
      tree_vals[left[left[i]]] != tree_vals[left[right[i]]] /\
      tree_vals[left[left[i]]] != tree_vals[right[right[i]]] /\
      tree_vals[right[left[i]]] != tree_vals[left[right[i]]] /\
      tree_vals[right[left[i]]] != tree_vals[right[right[i]]] /\
      true
    )
  )
);
% Distributivity of Division
% (a+b)/c = a/c + b/c
% (a-b)/c = a/c - b/c
constraint symmetry_breaking_constraint(
  forall (i in M) ((
    (tree[i] = Add \/ tree[i] = Sub) /\
    tree[left[i]] = Div /\ tree[right[i]] = Div) -> (
      tree_vals[right[left[i]]] != tree_vals[right[right[i]]] /\
      true
    )
  )
);
% TODO: check to see if the following two constraints are implied by the Symmetry constraints
constraint symmetry_breaking_constraint(
  forall (i in M) (
    (tree[i] = Add /\ tree[right[i]] = Val) -> tree[left[i]] = Val
  )
);
constraint symmetry_breaking_constraint(
  forall (i in M) (
    (tree[i] = Mul /\ tree[right[i]] = Val) -> tree[left[i]] = Val
  )
);
constraint symmetry_breaking_constraint(
  forall (i in M) (
    (tree[i] = Add /\ tree[left[i]] = Val /\ tree[right[i]] = Val) ->
      indexes[left[i]] < indexes[right[i]]
  )
);
constraint symmetry_breaking_constraint(
  forall (i in M) (
    (tree[i] = Mul /\ tree[left[i]] = Val /\ tree[right[i]] = Val) ->
      indexes[left[i]] < indexes[right[i]]
  )
);
constraint symmetry_breaking_constraint(
  forall (i in M) (
    (tree[i] = Add /\ tree[left[i]] = Val /\ tree[right[i]] = Add /\
      tree[left[right[i]]] = Val) ->
      indexes[left[i]] < indexes[left[right[i]]]
  )
);
constraint symmetry_breaking_constraint(
  forall (i in M) (
    (tree[i] = Mul /\ tree[left[i]] = Val /\ tree[right[i]] = Mul /\
      tree[left[right[i]]] = Val) ->
      indexes[left[i]] < indexes[left[right[i]]]
  )
);

% all numbers with the same value should be assigned in sorted order
constraint symmetry_breaking_constraint(
  forall (i in M) (
    forall (j in M where i < j) (
      (
        tree[i] = Val /\
        tree[j] = Val /\
        numbers[indexes[i]] = numbers[indexes[j]]
      ) -> indexes[i] < indexes[j]
    )
  )
);

% Sort the nodes of equivalent value
% This one might be invalid as 1 * 100 has 100 as a leaf
% TODO: This might not be good <don't know the word here>
% TODO: write a logical proof as to why this works or doesn't work
constraint symmetry_breaking_constraint(
  forall (i in M) (
    forall (j in M where i < j) (
      (
        tree_vals[i] = tree_vals[j]
      ) -> tree[i] >= tree[j]
    )
  )
);

*/

output [ if fix(tree[i]) != Null then
            "\(i): \(tree[i]) L \(left[i]) R \(right[i]) : \(value[i])\n" 
         else "" endif
       | i in NODE ];

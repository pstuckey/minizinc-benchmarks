% pizza voucher problem
%
% pizzas to order
%    13 25 17 12 9
% vouchers
%    1+1  2+1
% you pay for the most expensive pizzas when using a voucher.


int: n; % number of pizzas
enum PIZZA = P(1..n);         % a set of pizzas to buy
array[PIZZA] of int: price;   % price of each pizza

int: m;                       % number of vouchers
enum VOUCHER = V(1..m);       % a set of vouchers to help buy pizzas
array[VOUCHER] of int: buy;   % buy this many to use voucher
array[VOUCHER] of int: free;  % get this many free

enum ASSIGN = B(VOUCHER) ++   % B(i) pizza is assigned to buy of voucher i
              F(VOUCHER) ++   % F(i) pizza is assigned to free of voucher i
              { Purchase };   %      no voucher used on pizza

array[PIZZA] of var ASSIGN: how;
array[VOUCHER] of var bool: used;

% assign right number of pizzas to buy order
constraint forall(v in VOUCHER)(used[v] <-> sum(p in PIZZA)(how[p] = B(v)) >= buy[v]);
constraint forall(v in VOUCHER)(sum(p in PIZZA)(how[p] = B(v)) <= used[v]*buy[v]);
% assign not too many pizzas to free order
constraint forall(v in VOUCHER)(sum(p in PIZZA)(how[p] = F(v)) <= used[v]*free[v]);

% pizzas assigned to free are cheaper than pizzas assigned to buy
constraint forall(p1, p2 in PIZZA)(B^-1(how[p1]) = F^-1(how[p2]) -> price[p2] <= price[p1]);


int: total = sum(price);
var 0..total: objective = sum(p in PIZZA)((how[p] in B(VOUCHER) union { Purchase })*price[p]);


% symmetry breaking: always use better vouchers first
constraint symmetry_breaking_constraint(
           forall(v1, v2 in VOUCHER where 
                  buy[v1] <= buy[v2] /\ free[v1] >= free[v2] /\ (buy[v1] < buy[v2] \/ free[v1] > free[v2] \/ v1 < v2))
                 (used[v2] -> used[v1]));


solve :: int_search(how, input_order, indomain_min, complete)
      minimize objective;

output  
  ["how = "++show(how)++";\nobjective = "++show(objective)++";\n"];

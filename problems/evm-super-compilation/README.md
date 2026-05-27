# EVM Super-Compilation

## Problem Description

The **Ethereum Virtual Machine (EVM)** is a stack-based virtual machine that executes smart contract code on the Ethereum blockchain. Programs for the EVM consist of sequences of low-level instructions (opcodes) that manipulate a stack of data values.

This model tackles the **EVM super-compilation** (or superoptimization) problem: given a starting stack configuration and a required ending stack configuration, find the **shortest possible sequence of EVM instructions** that transforms the stack from start to end. The term "super-compilation" refers to finding _globally_ optimal code, rather than just applying local rewrite rules.

This kind of optimization is practically valuable for Ethereum smart contracts, where shorter and cheaper bytecode directly reduces the gas fees users pay for on-chain execution.

The model makes explicit references to a "CAV paper" (Computer-Aided Verification conference), which is the primary academic source for this formulation but is actually in PLDI.

- SuperStack: Superoptimization of Stack-Bytecode via Greedy, Constraint-Based, and SAT Techniques.
  Authors: Elvira Albert, Maria Garcia de la Banda, Alejandro Hernández-Cerezo, Alexey Ignatiev, Albert Rubio, Peter J. Stuckey.
  Proceedings of the ACM on Programming Languages, Volume 8, Issue PLDI.
  Article No.: 205, Pages 1437 - 1462
  https://doi.org/10.1145/3656435

---

## Stack and Instructions

The EVM uses a **stack** (a last-in, first-out data structure) where values are pushed on and popped off the top. The model supports the following categories of instruction:

| Instruction            | Effect on Stack             | Description                                                                                         |
| ---------------------- | --------------------------- | --------------------------------------------------------------------------------------------------- |
| **NOP**                | No change                   | Do nothing                                                                                          |
| **POP**                | Removes top element         | Discards the value at the top of the stack                                                          |
| **PUSH**               | Adds one element            | Places a specific known value on top of the stack                                                   |
| **ZERO** (zeroary ops) | Adds one element            | Computes a value requiring no stack inputs (e.g. `ADDRESS`)                                         |
| **UNARY**              | Replaces top element        | Applies a one-input operation to the top of the stack (e.g. `NOT`, `SLOAD`)                         |
| **BINARY**             | Removes top, updates second | Applies a two-input operation to the top two elements, leaving one result (e.g. `AND`, `OR`, `SHL`) |
| **STOR**               | Removes top two elements    | Stores a value in memory/storage using two arguments from the top of the stack                      |
| **DUP k**              | Adds one element            | Copies the element at depth _k_ to the top of the stack                                             |
| **SWAP k**             | No size change              | Swaps the top element with the element at depth _k+1_                                               |

Binary operations may be **commutative** (order of arguments does not matter) or non-commutative (order matters), and the model respects this distinction.

---

## Parameters

The instance data specifies:

- **`TERM`** — the set of symbolic data values that may appear on the stack (including a special `null` value representing an empty/unused stack slot).
- **`null`** — the specific element from `TERM` representing "nothing" (empty stack position).
- **`n`** — the maximum number of slots in the stack (stack depth limit).
- **`s`** — the maximum number of steps (instructions) allowed in the program.
- **`startstack`** — the initial contents of the stack (top element listed first).
- **`endstack`** — the required final contents of the stack (top element listed first).
- **Operation sets** (`ZEROARYOP`, `UNARYOP`, `BINARYOP`, `PUSHOP`, `STOROP`) — enumerations of the specific operations available in this instance, together with their input/output terms, gas costs, byte sizes, and allowed position bounds.
- **`before` / `after`** — precedence pairs arising from memory load/store operations: some instructions must appear before others in the sequence.

---

## Decision Variables

- **`stack[step, position]`** — the symbolic value at each stack position at each point in time (from step 0 to step `s`). This tracks the full state of the stack throughout execution.
- **`op[step]`** — the instruction executed at each step (from step 1 to step `s`).
- **`first[opcode]`** — the first step at which a given opcode appears (used to enforce precedence and uniqueness constraints).
- **`length`** — the total number of meaningful (non-NOP) instructions in the program. Steps beyond `length` are all NOPs.

---

## Constraints

The model enforces:

1. **Stack transition correctness** — the stack state after each step must be consistent with the instruction executed at that step (e.g. a UNARY op consumes a specific input term from the top and produces a specific output term).
2. **Start and end states** — the stack at step 0 must match `startstack`, and at step `s` must match `endstack`.
3. **NOP padding** — all steps after `length` must be NOP, and NOPs may only appear at the end.
4. **Instruction uniqueness** — certain instructions (non-trivial unary/binary/store ops and large push ops) must appear **exactly once** in the sequence.
5. **At-least-once** — other meaningful operations must appear at least once.
6. **Precedence** — memory load/store instructions must appear in the correct relative order.
7. **Bounds on instruction counts** — upper and lower bounds on how many times each opcode can appear, derived from data dependencies.
8. **Null propagation** — empty stack slots follow structural rules across steps.
9. **Dominance / shrinking** — in certain situations, it can be proven that an instruction's arguments should be computed immediately before it; these symmetry-breaking constraints reduce the search space without affecting optimality.

---

## Objective

**Minimize `length`** — find the shortest sequence of EVM instructions (fewest non-NOP steps) that correctly transforms the starting stack into the ending stack.

Alternative objectives (`totalgas`, `totalsize`) are computed and available in the output, representing the total gas cost and total bytecode size of the solution respectively, but the primary optimisation target is instruction count.

---

## Output

For each solution, the model outputs:

- The stack state at each step, visualised as a table (rows = steps, columns = stack positions).
- The total instruction count (`length`), gas cost (`gas`), and bytecode size (`bytes`).
- The full sequence of opcodes chosen (`solution`).

---

## References

SuperStack: Superoptimization of Stack-Bytecode via Greedy, Constraint-Based, and SAT Techniques.
  Authors: Elvira Albert, Maria Garcia de la Banda, Alejandro Hernández-Cerezo, Alexey Ignatiev, Albert Rubio, Peter J. Stuckey.
  Proceedings of the ACM on Programming Languages, Volume 8, Issue PLDI.
  Article No.: 205, Pages 1437 - 1462
  https://doi.org/10.1145/3656435

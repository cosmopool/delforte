## Rules
- run `flutter analyze` after done generating dart/flutter code and fix any problem
- run `flutter test` after done generating dart/flutter code and fix any failed test
- create tests to validade the feature/bug implementation. if refactoring and no tests exists to ensure feature parity, create it.
- always follow `.claude/rules/testing.md` when writing/editing/reviewing tests

## Decisions are mine — interview, don't assume

- Facts: if it can be found in the environment (filesystem, tools, git), look it up — never ask me for it.
- Decisions (approach, design, scope, tradeoffs, anything ambiguous): mine. Put each one to me with your recommended answer before acting on it — never silently pick for me.
- One question at a time; wait for my answer before the next question or any dependent work.
- Trivial calls with one obvious answer don't need a question — when in doubt, it's a decision: ask.
- Provide your recomendation when asking.

## General Code Style Rules

> Philosophy based on "Codin' Dirty" by Carson Gross — important things should be big, unimportant things should be little. Minimize the total number of functions, structs, interfaces, packages, layers, and concepts in the system. Less code and fewer abstractions beat "purist" decomposition.

## Core Principles

1. **Important things should be big; unimportant things should be little.** Size is a signal: a large "crux" function visibly announces "this is where the real work happens."
2. **Strive to minimize the total number of functions/structs/interfaces/packages/concepts in the project.** Every new abstraction is a cost: more code to read, more indirection to follow, more names to hold in your head. Only introduce one when it clearly pays for itself.

## core law

1. important code BIG. unimportant code little. size = signal.
2. count of function/struct/interface/package/concept: keep LOW. new abstraction = cost. must pay for self.

## functions

- big function fine. sometimes good. no split just for small.
- crux function: few per module, the real meat. no LOC limit. feel bad only past ~200-300.
- linear steps + much shared context = keep together. split hurt clarity + debug.
- split ONLY for real reuse or real clarity. not for size.
- many same-size tiny function = logic smeared. all look same. where meat? nobody know.
- never: split function because LOC number scary
- before split function ask:
    1. real reuse or real clarity gain? no → leave alone
    2. must thread much context between pieces? yes → leave alone

## structs, packages, interfaces

- no split struct/package for SRP dogma. split only when it become incoherent pile of unrelated stuff.
- if/else or switch is way better then interface dispatch. even long janky if/else or switch. interface only when impl many + stable.
- fat struct/package good. one type do db + domain logic + serialize for view = simple life.
  little view-flavor in struct (json/db tags etc)? fine. not end of world.
- true God package (incoherent pile) still bad. test = coherence, not size.
- NO DTO. NO mapper layer. NO parallel struct. pass real struct to encoder/template. twin struct = double work.
- accept interface only where consumer need it. define small, at point of use. return concrete struct.
- handle error where it happen. `if err != nil` inline good. no hide in clever abstraction. add context with `fmt.Errorf("...: %w", err)`.
- layer API: easy thing easy, medium thing ok, escape hatch to raw (SQL, raw bytes) when push come to shove.
- refactor make code 3x longer = regression. judge by TOTAL complexity: LOC + concepts + indirection.
- never: extraction that need pass many context/params around
- never: package/struct per "responsibility"
- never: strategy/factory/visitor struct replace simple if/else
- never: DTO mirror domain struct
- never: single-method interface, single-impl interface "for future". interface come from real second caller, not crystal ball.
- never: shatter coherent package from God-object fear
- before new struct/interface/package ask:
    1. remove more complexity than add?
    2. more than one real user/impl?
    3. function/conditional/field do same job? yes → do that
    4. total code + concepts go down?

## Other principles

## Data-oriented design
- Organize code around data and transformations.
- Prefer simple, flat structures and contiguous memory.
- Minimize indirection, pointer chasing, and cache misses.

## Performance awareness
- Assume performance matters unless proven otherwise.
- Avoid unnecessary allocations, copies, and dynamic dispatch (interface method calls in hot loops, needless `interface{}`/`any` boxing).
- Be aware of memory layout and access patterns. Prefer slices of values over slices of pointers; pre-size slices/maps with `make` when length is known.
- Optimize hot paths; keep cold paths simple.

## Debuggability first
- Code should be easy to step through in a debugger.
- Avoid dense or clever constructs.
- Favor explicit control flow and state transitions.

## Correctness by construction
- Make invalid states unrepresentable. Use distinct named types (not bare `string`/`int`) for ids, enums, units.
- Parse, don’t validate: convert input into trusted types early, at the boundary (decode/handler), not deep inside.
- Use types and structure to enforce invariants: unexported fields + a constructor (`NewX`) that returns `(X, error)` so a value can’t exist in a bad state.


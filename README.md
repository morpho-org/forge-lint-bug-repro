# forge lint `unsafe-typecast` — false negatives reproduction

Minimal repo demonstrating that `forge lint --only-lint unsafe-typecast` silently
misses narrowing / sign-changing casts when the inner expression is anything other
than a local variable, literal, cast chain, unary, or binary expression.

**forge version tested:** 1.5.1-stable (b0a9dd9ced 2025-12-22)

## Reproduce

```bash
forge lint --only-lint unsafe-typecast
```

### Expected

Warnings on every `uintN(...)` / `intN(...)` call in **both** `src/Detected.sol`
and `src/Missed.sol`.

### Actual

Only `src/Detected.sol` (and `Missed::castStateVar` if present as state-var-read
resolves to `Ident`) produce warnings. Every cast in `src/Missed.sol` is silently
skipped — **zero warnings**.

## What gets missed

| Category | Example expression | HIR `ExprKind` |
|---|---|---|
| Function return | `uint128(getAmount())` | `Call` (non-cast) |
| Struct member | `uint128(p.amount)` | `Member` |
| Array index | `uint128(amounts[0])` | `Index` |
| Mapping lookup | `uint128(balances[who])` | `Index` |
| Ternary | `uint128(flag ? a : b)` | `Ternary` |
| External call | `uint128(oracle.latestAnswer())` | `Call` (non-cast) |
| `msg.value` | `uint128(msg.value)` | `Member` (global) |
| `block.timestamp` | `uint64(block.timestamp)` | `Member` (global) |
| `type(T).max` | `uint128(type(uint256).max)` | `Member` |

## Root cause

In [`crates/lint/src/sol/med/unsafe_typecast.rs`](https://github.com/foundry-rs/foundry/blob/master/crates/lint/src/sol/med/unsafe_typecast.rs),
`infer_source_types` only handles five expression kinds:

```
ExprKind::Call  (only when it's a type-cast)
ExprKind::Ident
ExprKind::Lit
ExprKind::Unary
ExprKind::Binary
```

Everything else falls through a `_ => None` catch-all, which causes
`is_unsafe_typecast_hir` to return `false` (the `source_types` vec is empty).

## Suggested fix direction

Instead of trying to infer the source type by walking the expression tree,
the lint could use the HIR's resolved type information on the argument expression
directly. Since Solar's HIR already type-checks and resolves every expression,
this would cover all expression kinds uniformly.

If HIR type resolution isn't exposed, the fallback fix is to handle the missing
`ExprKind` variants (`Member`, `Index`, `Ternary`, non-cast `Call`) in
`infer_source_types`, potentially by looking up the function/field/mapping return
type from the HIR.

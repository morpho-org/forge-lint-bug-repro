# forge lint `unsafe-typecast` false negative

`forge lint` catches `uint128(x)` when `x` is a local variable, but silently
misses the exact same narrowing cast when the argument is a function return value.

**forge 1.5.1-stable** (b0a9dd9ced 2025-12-22)

## Reproduce

```
forge lint --only-lint unsafe-typecast
```

**Expected:** 2 warnings (lines 7 and 17).
**Actual:** 1 warning (line 7 only). The cast at line 17 is silently skipped.

## Root cause

`infer_source_types` in `crates/lint/src/sol/med/unsafe_typecast.rs` only
resolves types for `Ident`, `Lit`, cast-`Call`, `Unary`, and `Binary`
expressions. Any other `ExprKind` (including non-cast function calls, member
access, index, ternary, globals) falls through `_ => None`, making the
source-type vec empty and the cast appear safe.

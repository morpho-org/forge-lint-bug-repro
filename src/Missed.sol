// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    function latestAnswer() external view returns (uint256);
}

/// @title Cases the linter MISSES (the bug)
/// @dev Every narrowing/sign-change cast below is silently skipped by
///      `forge lint --only-lint unsafe-typecast` because `infer_source_types`
///      returns `None` for the inner expression, so the cast is never evaluated.
///
///      Root cause: the `_ => None` catch-all in `infer_source_types`
///      (crates/lint/src/sol/med/unsafe_typecast.rs) drops any expression kind
///      that isn't Ident, Lit, Call(cast), Unary, or Binary.
///
///      See: https://github.com/foundry-rs/foundry/blob/master/crates/lint/src/sol/med/unsafe_typecast.rs
contract Missed {

    // ── A: Function return value ──────────────────────────────────────────
    function getAmount() public pure returns (uint256) {
        return type(uint256).max;
    }

    /// @dev uint256 → uint128 on internal call return. MISSED.
    function castFunctionReturn() external pure returns (uint128) {
        return uint128(getAmount());
    }

    // ── B: Struct member access ───────────────────────────────────────────
    struct Position {
        uint256 amount;
        int256  delta;
    }

    /// @dev uint256 → uint128 on struct field. MISSED.
    function castStructField() external pure returns (uint128) {
        Position memory p = Position(type(uint256).max, -1);
        return uint128(p.amount);
    }

    // ── C: Array index ────────────────────────────────────────────────────
    uint256[] public amounts;

    /// @dev uint256 → uint128 on dynamic array element. MISSED.
    function castArrayIndex() external view returns (uint128) {
        return uint128(amounts[0]);
    }

    // ── D: Mapping lookup ─────────────────────────────────────────────────
    mapping(address => uint256) public balances;

    /// @dev uint256 → uint128 on mapping value. MISSED.
    function castMappingValue(address who) external view returns (uint128) {
        return uint128(balances[who]);
    }

    // ── E: Ternary / conditional ──────────────────────────────────────────

    /// @dev uint256 → uint128 on ternary. MISSED.
    function castTernary(uint256 a, uint256 b, bool flag) external pure returns (uint128) {
        return uint128(flag ? a : b);
    }

    // ── F: External call ──────────────────────────────────────────────────

    /// @dev uint256 → uint128 on external call return. MISSED.
    function castExternalCall(IOracle oracle) external view returns (uint128) {
        return uint128(oracle.latestAnswer());
    }

    // ── G: Global / built-in members ──────────────────────────────────────

    /// @dev uint256 → uint128 on msg.value. MISSED.
    function castMsgValue() external payable returns (uint128) {
        return uint128(msg.value);
    }

    /// @dev uint256 → uint64 on block.timestamp. MISSED.
    function castBlockTimestamp() external view returns (uint64) {
        return uint64(block.timestamp);
    }

    // ── H: type(T).max / type(T).min ─────────────────────────────────────

    /// @dev uint256 → uint128 on type(uint256).max. MISSED.
    function castTypeMax() external pure returns (uint128) {
        return uint128(type(uint256).max);
    }

    // ── Safe casts (should NEVER be flagged) ──────────────────────────────

    function safeWiden(uint128 x) external pure returns (uint256) {
        return uint256(x);
    }

    function safeIdentity(uint256 x) external pure returns (uint256) {
        return uint256(x);
    }
}

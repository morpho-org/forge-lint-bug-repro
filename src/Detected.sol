// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Cases the linter DOES catch (control group)
/// @dev All casts below are correctly flagged by `forge lint --only-lint unsafe-typecast`.
contract Detected {
    // Narrowing: local variable → smaller uint
    function localNarrow(uint256 x) external pure returns (uint128) {
        return uint128(x);
    }

    // Narrowing chain through locals
    function chainedNarrow(uint256 x) external pure returns (uint64) {
        uint128 mid = uint128(x);  // flagged
        return uint64(mid);        // flagged
    }

    // Sign change: int → uint
    function signedToUnsigned(int256 x) external pure returns (uint256) {
        return uint256(x);
    }

    // Sign change: uint → int (same width)
    function unsignedToSigned(uint256 x) external pure returns (int256) {
        return int256(x);
    }

    // Narrowing on binary expression of locals
    function binaryNarrow(uint256 a, uint256 b) external pure returns (uint128) {
        return uint128(a + b);
    }

    // Narrowing on state variable (treated as Ident/Variable in HIR)
    uint256 public totalSupply;
    function stateVarNarrow() external view returns (uint128) {
        return uint128(totalSupply);
    }
}

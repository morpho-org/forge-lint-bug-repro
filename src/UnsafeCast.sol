// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UnsafeCast {
    // Caught: narrowing cast on local variable
    function caught(uint256 x) external pure returns (uint128) {
        return uint128(x);
    }

    // Missed: same narrowing cast on function return
    function _get() internal pure returns (uint256) {
        return type(uint256).max;
    }

    function missed() external pure returns (uint128) {
        return uint128(_get());
    }
}

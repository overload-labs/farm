// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "./IERC20.sol";

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit Ether to get Wrapped Ether.
    function deposit() external payable;

    /// @notice Withdraw Wrapped Ether to get Ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "./interfaces/IERC20.sol";
import {Lock} from "./libraries/Lock.sol";
import {TokenId} from "./libraries/TokenId.sol";
import {ERC6909} from "./token/ERC6909.sol";

contract Farm is ERC6909, Lock {
    using TokenId for uint256;
    using TokenId for address;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event Deposit(address indexed caller, address owner, address indexed token, uint256 amount, uint32 timestamp);
    event Withdraw(address indexed caller, address owner, address indexed token, uint256 amount, address recipient, uint32 timestamp);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          METHODS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Deposit ERC-20 tokens into the contract.
    /// @dev The contract does not support rebasing tokens, although fee-on-transfer works fine as the difference
    ///     is the amount that's accounted for, not the input argument.
    /// @param owner The address to credit the deposit to.
    /// @param token The ERC-20 token to deposit.
    /// @param amount The transfer amount.
    function deposit(address owner, address token, uint256 amount) public lock returns (bool) {
        require(amount > 0, "ZERO");

        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        uint256 deposited = IERC20(token).balanceOf(address(this)) - balance;
        _mint(owner, token.convertToId(), deposited);

        emit Deposit(msg.sender, owner, token, deposited, uint32(block.timestamp));

        return true;
    }

    /// @notice Withdraw ERC-20 tokens from the contract.
    /// @param owner The address to withdraw from.
    /// @param token The ERC-20 token to deposit.
    /// @param amount The transfer amount.
    /// @param recipient The recipient of the ERC-20 tokens.
    function withdraw(address owner, address token, uint256 amount, address recipient) public lock returns (bool) {
        if (msg.sender != owner && !isOperator[owner][msg.sender]) {
            uint256 allowed = allowance[owner][msg.sender][token.convertToId()];

            if (allowed != type(uint256).max) {
                allowance[owner][msg.sender][token.convertToId()] = allowed - amount;
            }
        }
        require(amount > 0, "ZERO");

        _burn(owner, token.convertToId(), amount);
        IERC20(token).transfer(recipient, amount);

        emit Withdraw(msg.sender, owner, token, amount, recipient, uint32(block.timestamp));

        return true;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OVERRIDES                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function transfer(address, uint256, uint256) public override pure returns (bool) {
        revert("DISABLED");
    }

    function transferFrom(address, address, uint256, uint256) public override pure returns (bool) {
        revert("DISABLED");
    }
}

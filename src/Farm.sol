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

    function deposit(address owner, address token, uint256 amount) public lock returns (bool) {
        require(amount > 0, "ZERO");

        _mint(owner, token.convertToId(), amount);
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, owner, token, amount, uint32(block.timestamp));

        return true;
    }

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
        revert();
    }

    function transferFrom(address, address, uint256, uint256) public override pure returns (bool) {
        revert();
    }
}

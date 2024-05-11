// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {Lock} from "../../src/libraries/Lock.sol";
import {TokenId} from "../../src/libraries/TokenId.sol";
import {ERC6909} from "../../src/token/ERC6909.sol";

contract TargetMock is ERC6909, Lock {
    function deposit(address owner, address token, uint256 amount) public lock returns (bool) {
        require(amount > 0, "ZERO");

        _mint(owner, TokenId.convertToId(token), amount);
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        return true;
    }
}

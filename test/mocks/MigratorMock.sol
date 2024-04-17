// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "../../src/interfaces/IERC20.sol";
import {Farm} from "../../src/Farm.sol";
import {TargetMock} from "./TargetMock.sol";

contract MigratorMock {
    function migrate(address farm, address target, address token, uint256 amount) public {
        Farm(farm).withdraw(msg.sender, token, amount, address(this));
        IERC20(token).approve(target, amount);
        TargetMock(target).deposit(msg.sender, token, amount);
    }
}

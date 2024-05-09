// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "./interfaces/IERC20.sol";
import {IWETH9} from "./interfaces/IWETH9.sol";
import {Payment} from "./libraries/Payment.sol";
import {Farm} from "./Farm.sol";

contract Router is Payment {
    address public farm;

    constructor(address _farm, address _weth9) {
        require(_farm != address(0), "ZERO_0");
        require(_weth9 != address(0), "ZERO_1");

        farm = _farm;
        WETH9 = _weth9;
    }

    function deposit(address token, uint256 amount) public payable returns (bool) {
        if (token == WETH9) {
            require(amount == msg.value, "NOT_EQUAL_VALUE");
        } else {
            require(msg.value == 0, "HAS_VALUE");
        }

        pay(token, msg.sender, address(this), amount);
        IERC20(token).approve(farm, amount);
        return Farm(farm).deposit(msg.sender, token, amount);
    }

    function withdraw(address token, uint256 amount) public payable returns (bool) {
        Farm(farm).withdraw(msg.sender, token, amount, address(this));

        if (token == WETH9) {
            IWETH9(WETH9).withdraw(amount);
            safeTransferETH(msg.sender, amount);
        } else {
            pay(token, address(this), msg.sender, amount);
        }

        return true;
    }
}

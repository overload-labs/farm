// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

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

        uint256 balance = IERC20(token).balanceOf(address(this));
        pay(token, msg.sender, address(this), amount);
        uint256 deposited = IERC20(token).balanceOf(address(this)) - balance;

        SafeERC20.forceApprove(IERC20(token), farm, deposited);
        return Farm(farm).deposit(msg.sender, token, deposited);
    }

    function withdraw(address token, uint256 amount) public returns (bool) {
        if (token == WETH9) {
            Farm(farm).withdraw(msg.sender, token, amount, address(this));

            IWETH9(WETH9).withdraw(amount);
            safeTransferETH(msg.sender, amount);
        } else {
            uint256 balance = IERC20(token).balanceOf(address(this));
            Farm(farm).withdraw(msg.sender, token, amount, address(this));
            uint256 withdrawn = IERC20(token).balanceOf(address(this)) - balance;

            pay(token, address(this), msg.sender, withdrawn);
        }

        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";

import {TokenId} from "../../src/libraries/TokenId.sol";
import {Farm} from "../src/Farm.sol";

import {ERC20Mock} from "./mocks/ERC20Mock.sol";

contract FarmTest is Test {
    using TokenId for uint256;
    using TokenId for address;

    Farm public farm;
    ERC20Mock public token;

    function setUp() public {
        farm = new Farm();
        token = new ERC20Mock("Test", "TEST", 18);
    }

    function test_deposit() public {
        token.mint(address(0xBEEF), 100);

        vm.prank(address(0xBEEF));
        token.approve(address(farm), 100);

        vm.prank(address(0xBEEF));
        farm.deposit(address(0xBEEF), address(token), 100);

        assertEq(farm.balanceOf(address(0xBEEF), address(token).convertToId()), 100);
    }

    function test_withdraw() public {
        token.mint(address(0xBEEF), 100);
        vm.prank(address(0xBEEF));
        token.approve(address(farm), 100);
        vm.prank(address(0xBEEF));
        farm.deposit(address(0xBEEF), address(token), 100);

        vm.prank(address(0xBEEF));
        farm.withdraw(address(0xBEEF), address(token), 100, address(0xBEEF));

        assertEq(farm.balanceOf(address(0xBEEF), address(token).convertToId()), 0);
        assertEq(token.balanceOf(address(0xBEEF)), 100);
    }

    function test_withdraw_isOperator() public {
        token.mint(address(0xBEEF), 100);
        vm.prank(address(0xBEEF));
        token.approve(address(farm), 100);
        vm.prank(address(0xBEEF));
        farm.deposit(address(0xBEEF), address(token), 100);

        vm.prank(address(0xBEEF));
        farm.setOperator(address(0xABCD), true);
        vm.prank(address(0xABCD));
        farm.withdraw(address(0xBEEF), address(token), 100, address(0xABCD));

        assertEq(farm.balanceOf(address(0xBEEF), address(token).convertToId()), 0);
        assertEq(token.balanceOf(address(0xABCD)), 100);
    }

    function testFail_withdraw_notOperator() public {
        token.mint(address(0xBEEF), 100);
        vm.prank(address(0xBEEF));
        token.approve(address(farm), 100);
        vm.prank(address(0xBEEF));
        farm.deposit(address(0xBEEF), address(token), 100);

        vm.prank(address(0xABCD));
        farm.withdraw(address(0xBEEF), address(token), 100, address(0xBEEF));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console, console2, stdError} from "forge-std/Test.sol";

import {TokenId} from "../src/libraries/TokenId.sol";
import {Farm} from "../src/Farm.sol";

import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {ERC20Fee} from "./mocks/ERC20Fee.sol";

contract FarmTest is Test {
    using TokenId for uint256;
    using TokenId for address;

    event Deposit(address indexed caller, address owner, address indexed token, uint256 amount, uint32 timestamp);
    event Withdraw(address indexed caller, address owner, address indexed token, uint256 amount, address recipient, uint32 timestamp);

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
        vm.expectEmit(true, true, true, true);
        emit Deposit(address(0xBEEF), address(0xBEEF), address(token), 100, uint32(block.timestamp));
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
        vm.expectEmit(true, true, true, true);
        emit Withdraw(address(0xBEEF), address(0xBEEF), address(token), 100, address(0xBEEF), uint32(block.timestamp));
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

    function test_transfer_failDisabled() public {
        token.mint(address(0xBEEF), 100);

        vm.prank(address(0xBEEF));
        token.approve(address(farm), 100);

        vm.prank(address(0xBEEF));
        farm.deposit(address(0xBEEF), address(token), 100);

        vm.prank(address(0xBEEF));
        vm.expectRevert(abi.encodePacked("DISABLED"));
        farm.transfer(address(0xBEEF), address(token).convertToId(), 100);
    }

    function test_transferFrom_failDisabled() public {
        token.mint(address(0xBEEF), 100);

        vm.prank(address(0xBEEF));
        token.approve(address(farm), 100);

        vm.prank(address(0xBEEF));
        farm.deposit(address(0xBEEF), address(token), 100);

        vm.prank(address(0xBEEF));
        vm.expectRevert(abi.encodePacked("DISABLED"));
        farm.transferFrom(address(0xBEEF), address(0xABCD), address(token).convertToId(), 100);
    }

    /*//////////////////////////////////////////////////////////////
                                  FEE
    //////////////////////////////////////////////////////////////*/

    function test_deposit_fee() public {
        vm.prank(address(0xBEEF));
        ERC20Fee tokenFee = new ERC20Fee(1e18, 1_000);

        vm.prank(address(0xBEEF));
        tokenFee.approve(address(farm), 10_000);

        vm.prank(address(0xBEEF));
        vm.expectEmit(true, true, true, true);
        emit Deposit(address(0xBEEF), address(0xBEEF), address(tokenFee), 9_000, uint32(block.timestamp));
        farm.deposit(address(0xBEEF), address(tokenFee), 10_000);

        assertEq(farm.balanceOf(address(0xBEEF), address(tokenFee).convertToId()), 9_000);
    }

    function test_withdraw_fee() public {
        vm.prank(address(0xBEEF));
        ERC20Fee tokenFee = new ERC20Fee(1e18, 1_000);

        vm.prank(address(0xBEEF));
        tokenFee.approve(address(farm), 10_000);
        vm.prank(address(0xBEEF));
        farm.deposit(address(0xBEEF), address(tokenFee), 10_000);

        vm.prank(address(0xBEEF));
        vm.expectEmit(true, true, true, true);
        emit Withdraw(address(0xBEEF), address(0xBEEF), address(tokenFee), 9_000, address(0xBEEF), uint32(block.timestamp));
        farm.withdraw(address(0xBEEF), address(tokenFee), 9_000, address(0xBEEF));

        assertEq(farm.balanceOf(address(0xBEEF), address(tokenFee).convertToId()), 0);
        assertEq(tokenFee.balanceOf(address(0xBEEF)), 1e18 - 2_000);
    }

    /*//////////////////////////////////////////////////////////////
                                  FUZZ
    //////////////////////////////////////////////////////////////*/

    function test_deposit(address owner, uint256 amount) public {
        if (owner == address(farm)) {
            return;
        }

        token.mint(owner, amount);

        vm.prank(owner);
        token.approve(address(farm), amount);

        if (amount == 0) {
            vm.prank(owner);
            vm.expectRevert(abi.encodePacked("ZERO"));
            farm.deposit(owner, address(token), amount);
        } else {
            vm.prank(owner);
            vm.expectEmit(true, true, true, true);
            console2.log(block.timestamp);
            emit Deposit(owner, owner, address(token), amount, uint32(block.timestamp));
            assertTrue(farm.deposit(owner, address(token), amount));
        }

        assertEq(farm.balanceOf(owner, address(token).convertToId()), amount);
    }

    function test_withdraw(address owner, uint256 depositAmount, uint256 withdrawAmount, address recipient) public {
        if (owner == address(farm)) {
            return;
        }

        token.mint(owner, depositAmount);

        vm.prank(owner);
        token.approve(address(farm), depositAmount);
        if (depositAmount == 0) {
            vm.prank(owner);
            vm.expectRevert(abi.encodePacked("ZERO"));
            farm.deposit(owner, address(token), depositAmount);
        } else {
            vm.prank(owner);
            assertTrue(farm.deposit(owner, address(token), depositAmount));
        }

        if (withdrawAmount == 0) {
            vm.prank(owner);
            vm.expectRevert(abi.encodePacked("ZERO"));
            farm.withdraw(owner, address(token), withdrawAmount, owner);
        } else if (withdrawAmount > depositAmount) {
            vm.prank(owner);
            vm.expectRevert(stdError.arithmeticError);
            farm.withdraw(owner, address(token), withdrawAmount, owner);
        } else {
            vm.prank(owner);
            vm.expectEmit(true, true, true, true);
            emit Withdraw(owner, owner, address(token), withdrawAmount, recipient, uint32(block.timestamp));
            assertTrue(farm.withdraw(owner, address(token), withdrawAmount, recipient));
            
            assertEq(farm.balanceOf(owner, address(token).convertToId()), depositAmount - withdrawAmount);

            if (recipient != address(farm)) {
                assertEq(token.balanceOf(recipient), withdrawAmount);
            }
        }
    }
}

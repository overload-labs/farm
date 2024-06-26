// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";

import {TokenId} from "../src/libraries/TokenId.sol";
import {Farm} from "../src/Farm.sol";

import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {MigratorMock} from "./mocks/MigratorMock.sol";
import {TargetMock} from "./mocks/TargetMock.sol";

contract FarmMigrateTest is Test {
    using TokenId for uint256;
    using TokenId for address;

    Farm public farm;
    ERC20Mock public token;
    MigratorMock public migrator;
    TargetMock public target;

    function setUp() public {
        farm = new Farm();
        token = new ERC20Mock("Test", "TEST", 18);
        migrator = new MigratorMock();
        target = new TargetMock();
    }

    function test_migrate() public {
        token.mint(address(0xBEEF), 100);

        vm.prank(address(0xBEEF));
        token.approve(address(farm), 100);

        vm.prank(address(0xBEEF));
        farm.deposit(address(0xBEEF), address(token), 100);

        vm.prank(address(0xBEEF));
        farm.setOperator(address(migrator), true);

        vm.prank(address(0xBEEF));
        migrator.migrate(address(farm), address(target), address(token), 100);

        assertEq(farm.balanceOf(address(0xBEEF), address(token).convertToId()), 0);
        assertEq(target.balanceOf(address(0xBEEF), address(token).convertToId()), 100);
    }
}

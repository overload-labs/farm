// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

import {Test, console} from "forge-std/Test.sol";

import {TokenId} from "../src/libraries/TokenId.sol";
import {Farm} from "../src/Farm.sol";
import {Router} from "../src/Router.sol";

import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {ERC20Fee} from "./mocks/ERC20Fee.sol";
import {WETH9} from "./mocks/WETH9.sol";

contract RouterTest is Test {
    using TokenId for uint256;
    using TokenId for address;

    Farm public farm;
    WETH9 public weth;
    Router public router;
    ERC20Mock public token;

    function setUp() public {
        farm = new Farm();
        weth = new WETH9();
        router = new Router(address(farm), address(weth));
        token = new ERC20Mock("Test", "TEST", 18);
    }

    /*//////////////////////////////////////////////////////////////
                                  FEE
    //////////////////////////////////////////////////////////////*/

    function test_deposit_fee() public {
        vm.prank(address(0xBEEF));
        ERC20Fee tokenFee = new ERC20Fee(1e18, 1_000);

        vm.prank(address(0xBEEF));
        tokenFee.approve(address(router), 10_000);
        vm.prank(address(0xBEEF));
        router.deposit(address(tokenFee), 10_000);

        assertEq(tokenFee.balanceOf(address(farm)), 8_000);
        assertEq(farm.balanceOf(address(0xBEEF), address(tokenFee).convertToId()), 8_000);
    }

    function test_withdraw_fee() public {
        vm.prank(address(0xBEEF));
        ERC20Fee tokenFee = new ERC20Fee(1e18, 1_000);

        vm.prank(address(0xBEEF));
        tokenFee.approve(address(router), 10_000);
        vm.prank(address(0xBEEF));
        router.deposit(address(tokenFee), 10_000);

        assertEq(tokenFee.balanceOf(address(farm)), 8_000);
        assertEq(farm.balanceOf(address(0xBEEF), address(tokenFee).convertToId()), 8_000);

        vm.prank(address(0xBEEF));
        farm.setOperator(address(router), true);
        vm.prank(address(0xBEEF));
        router.withdraw(address(tokenFee), 8_000);

        assertEq(farm.balanceOf(address(0xBEEF), address(tokenFee).convertToId()), 0);
        assertEq(tokenFee.balanceOf(address(0xBEEF)), 1e18 - 4_000);
    }
}

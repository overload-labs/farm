// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

import {TokenId} from "../src/libraries/TokenId.sol";
import {Farm} from "../src/Farm.sol";

import {ERC20Mock} from "./mocks/ERC20Mock.sol";

contract Attacker is ERC20 {
    constructor(string memory name, string memory symbol, uint8 decimals)
        ERC20(name, symbol, decimals) {}

    function transferFrom(address from, address, uint256 amount) public override returns (bool) {
        Farm(msg.sender).deposit(from, address(this), amount);

        return true;
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }
}

contract ReentrancyTest is Test {
    using TokenId for uint256;
    using TokenId for address;

    Farm public farm;
    Attacker public token;

    function setUp() public {
        farm = new Farm();
        token = new Attacker("Test", "TEST", 18);
    }

    function testFail_deposit() public {
        token.mint(address(0xBEEF), 100);

        vm.prank(address(0xBEEF));
        token.approve(address(farm), 100);

        vm.prank(address(0xBEEF));
        farm.deposit(address(0xBEEF), address(token), 100);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;
pragma abicoder v2;

import {Test, console} from "forge-std/Test.sol";
import {DeployGSP} from "../scripts/DeployGSP.s.sol";
import {GSP} from "../contracts/GasSavingPool/impl/GSP.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestGSPFunding is Test {
    GSP gsp;

    address USER = vm.addr(1);
    address OTHER = vm.addr(2);
    address constant USDC_WHALE = 0x51eDF02152EBfb338e03E30d65C15fBf06cc9ECC;
    address constant DAI_WHALE = 0x25B313158Ce11080524DcA0fD01141EeD5f94b81;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    IERC20 private usdc = IERC20(USDC);
    IERC20 private dai = IERC20(DAI);

    // Test Params
    uint256 constant BASE_RESERVE = 1e19; // 10 DAI
    uint256 constant QUOTE_RESERVE = 1e7; // 10 USDC
    uint256 constant BASE_INPUT = 1e18; // 1 DAI
    uint256 constant QUOTE_INPUT = 2e6; // 2 USDC


    function setUp() public {
        // Deploy and Init 
        DeployGSP deployGSP = new DeployGSP();
        gsp = deployGSP.run();

        // transfer some tokens to USER
        vm.startPrank(DAI_WHALE);
        dai.transfer(USER, BASE_RESERVE + BASE_INPUT);
        vm.stopPrank();
        vm.startPrank(USDC_WHALE);
        usdc.transfer(USER, QUOTE_RESERVE + QUOTE_INPUT);
        vm.stopPrank();
    }

    function test_buySharesForTwice() public {
        vm.startPrank(USER);
        // dai.transfer(address(gsp), BASE_RESERVE);
        // vm.expectRevert();
        // gsp.buyShares(USER);

        dai.transfer(address(gsp), BASE_RESERVE);
        usdc.transfer(address(gsp), QUOTE_RESERVE);
        gsp.buyShares(USER);
        assertTrue(gsp._BASE_RESERVE_() == BASE_RESERVE);
        assertTrue(gsp._QUOTE_RESERVE_() == QUOTE_RESERVE);
        dai.transfer(address(gsp), BASE_INPUT);
        usdc.transfer(address(gsp), QUOTE_INPUT);
        gsp.buyShares(USER);
        vm.stopPrank();
    }

    function test_userTransferSharesToOther() public {
        // User buys shares
        vm.startPrank(USER);
        dai.transfer(address(gsp), BASE_RESERVE);
        usdc.transfer(address(gsp), QUOTE_RESERVE);
        gsp.buyShares(USER);
        uint256 userSharesBefore = gsp.balanceOf(USER);
        gsp.transfer(OTHER, gsp.balanceOf(USER));
        uint256 userSharesAfter = gsp.balanceOf(USER);
        assertEq(userSharesAfter, 0);
        uint256 otherShares = gsp.balanceOf(OTHER);
        vm.stopPrank();
        assertTrue(otherShares == (userSharesBefore - userSharesAfter));
    }

    function test_otherTransferSharesFromUser() public {
        // User buys shares
        vm.startPrank(USER);
        dai.transfer(address(gsp), BASE_RESERVE);
        usdc.transfer(address(gsp), QUOTE_RESERVE);
        gsp.buyShares(USER);
        uint256 userSharesBefore = gsp.balanceOf(USER);
        gsp.approve(OTHER, gsp.balanceOf(USER));
        assertEq(gsp.allowance(USER, OTHER), gsp.balanceOf(USER));
        vm.stopPrank();

        // Other transfers shares from user
        vm.startPrank(OTHER);
        gsp.transferFrom(USER, OTHER, gsp.balanceOf(USER));
        uint256 userSharesAfter = gsp.balanceOf(USER);
        assertEq(userSharesAfter, 0);
        uint256 otherShares = gsp.balanceOf(OTHER);
        vm.stopPrank();
        assertTrue(otherShares == (userSharesBefore - userSharesAfter));
    }

    function test_buySharesWithNoBaseInput() public {
        vm.startPrank(USER);
        usdc.transfer(address(gsp), QUOTE_RESERVE);
        vm.expectRevert("NO_BASE_INPUT");
        gsp.buyShares(USER);
    }

    function test_sellSharesWhenTimeExpired() public {
        vm.startPrank(USER);
        dai.transfer(address(gsp), BASE_RESERVE);
        usdc.transfer(address(gsp), QUOTE_RESERVE);
        gsp.buyShares(USER);
        uint256 shares = gsp.balanceOf(USER);
        vm.expectRevert("TIME_EXPIRED");
        gsp.sellShares(shares, USER, 0, 0, "", block.timestamp - 100000);
    }

    function test_sellSharesWhenDLPIsNotEnough() public {
        vm.startPrank(USER);
        dai.transfer(address(gsp), BASE_RESERVE);
        usdc.transfer(address(gsp), QUOTE_RESERVE);
        gsp.buyShares(USER);
        uint256 shares = gsp.balanceOf(USER) + 1000;
        vm.expectRevert("GLP_NOT_ENOUGH");
        gsp.sellShares(shares, USER, 0, 0, "", block.timestamp);
    }

    function test_sellSharesWhenWithdrawNotEnough() public {
        vm.startPrank(USER);
        dai.transfer(address(gsp), BASE_RESERVE);
        usdc.transfer(address(gsp), QUOTE_RESERVE);
        gsp.buyShares(USER);
        uint256 shares = gsp.balanceOf(USER);
        vm.expectRevert("WITHDRAW_NOT_ENOUGH");
        gsp.sellShares(shares, USER, type(uint256).max, type(uint256).max, "", block.timestamp);
    }

    function test_sellSharesWithDataIsNotEmpty() public {
        vm.startPrank(USER);
        dai.transfer(address(gsp), BASE_RESERVE);
        usdc.transfer(address(gsp), QUOTE_RESERVE);
        gsp.buyShares(USER);
        uint256 shares = gsp.balanceOf(USER);
        vm.expectRevert();
        gsp.sellShares(shares, USER, 0, 0, "Test", block.timestamp);
    }
}
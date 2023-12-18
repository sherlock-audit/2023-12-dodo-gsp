// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import {Test, console} from "forge-std/Test.sol";
import {StableSwap} from "../scripts/StableSwap.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestGasFee is Test {
    StableSwap stableSwap;
    address constant USDC_WHALE = 0x51eDF02152EBfb338e03E30d65C15fBf06cc9ECC;
    address constant DAI_WHALE = 0x25B313158Ce11080524DcA0fD01141EeD5f94b81;

    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    IERC20 private dai = IERC20(DAI);
    IERC20 private usdc = IERC20(USDC);


    function setUp() public {
       stableSwap = new StableSwap();
    }

    function test_compareGasFee() public {
        stableSwap.dspAdvanced_addLiquidity();
        stableSwap.ogp_addLiquidity();

        vm.startPrank(DAI_WHALE);
        dai.approve(address(stableSwap), type(uint256).max);
        uint256 amountOut1 = stableSwap.dsp_sellBase(DAI, 1e18, address(this));
        uint256 amountOut2 = stableSwap.gsp_sellBase(DAI, 1e18, address(this));
        uint256 amountOut3 = stableSwap.ogp_sellBase(DAI, 1e18, address(this));
        vm.stopPrank();

        vm.startPrank(USDC_WHALE);
        usdc.approve(address(stableSwap), type(uint256).max);
        uint256 amountOut4 = stableSwap.uniV3_exactInputSingle(USDC, USDT, 3000, 1e6);
        vm.stopPrank();
        
        console.log("DSP: receive USDT amount", amountOut1);
        console.log("GSP: receive USDC amount", amountOut2);
        console.log("OGP: receive USDC amount", amountOut3);
        console.log("UniV3: receive USDT amount", amountOut4);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
pragma abicoder v2;

import "../lib/forge-std/src/Script.sol";
import "../lib/forge-std/src/console.sol";

import {DeployGSP} from "../scripts/DeployGSP.s.sol";

import {OGP} from "../contracts/OptimalGasPool/impl/OGP.sol";
import {GSP} from "../contracts/GasSavingPool/impl/GSP.sol";
import {IDSP} from "../contracts/DODOStablePool/intf/IDSP.sol";
import {ISwapRouter} from "../contracts/UniV3/intf/ISwapRouter.sol";
import {IERC20} from "../contracts/DODOStablePool/intf/IERC20.sol";


contract StableSwap is Script {

    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    IERC20 private dai = IERC20(DAI);
    IERC20 private usdc = IERC20(USDC);

    address constant UniV3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant USDC_WHALE = 0x51eDF02152EBfb338e03E30d65C15fBf06cc9ECC;
    address constant DAI_WHALE = 0x25B313158Ce11080524DcA0fD01141EeD5f94b81;
    address LP = vm.addr(1);
    
    DeployGSP deployGSP = new DeployGSP();
    GSP gsp = deployGSP.run(); // DAI-USDC
    ISwapRouter uniV3Router = ISwapRouter(UniV3_ROUTER);

    IDSP dsp = IDSP(0x3058EF90929cb8180174D74C507176ccA6835D73); // DAI-USDT

    OGP ogp = new OGP(); // USDC-USDT

    function dspAdvanced_addLiquidity() external {
        // provide liquidity to GSP
        (uint256 baseReserve, uint256 quoteReserve) = dsp.getVaultReserve();

        // whales send tokens to LP
        vm.startPrank(DAI_WHALE);
        dai.transfer(LP, baseReserve);
        vm.stopPrank();

        vm.startPrank(USDC_WHALE);
        usdc.transfer(LP, quoteReserve);
        vm.stopPrank();

        // LP provide liquidity to GSP
        vm.startPrank(LP);
        dai.transfer(address(gsp), baseReserve);
        usdc.transfer(address(gsp), quoteReserve);
        gsp.buyShares(msg.sender);
        vm.stopPrank();
        
        console.log("baseReserve: %s", gsp._BASE_RESERVE_());
        console.log("quoteReserve: %s", gsp._QUOTE_RESERVE_());
    }


    function dsp_sellBase(address tokenIn, uint256 amount, address to) external returns (uint256) {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amount);
        IERC20(tokenIn).transfer(address(dsp), amount);
        return dsp.sellBase(to);
    }

    function gsp_sellBase(address tokenIn, uint256 amount, address to) external returns (uint256) {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amount);
        IERC20(tokenIn).transfer(address(gsp), amount);
        return gsp.sellBase(to);
    }

    function uniV3_exactInputSingle(address tokenIn, address tokenOut, uint24 fee, uint amountIn) external returns (uint256) {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(address(uniV3Router), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: fee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        return uniV3Router.exactInputSingle(params);
    }

    function ogp_addLiquidity() external {
        vm.startPrank(DAI_WHALE);
        dai.transfer(address(ogp), 2e18);
        vm.stopPrank();

        vm.startPrank(USDC_WHALE);
        usdc.transfer(address(ogp), 2e6);
        vm.stopPrank();

        ogp.sync();
    }

    function ogp_sellBase(address tokenIn, uint256 amount, address to) external returns (uint256) {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amount);
        IERC20(tokenIn).transfer(address(ogp), amount);
        return ogp.sellBase(to);
    }
}
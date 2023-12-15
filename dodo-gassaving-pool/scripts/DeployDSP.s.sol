// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import {Script} from "../lib/forge-std/src/Script.sol";
import "../lib/forge-std/src/console.sol";


import {DSP} from "../contracts/DODOStablePool/impl/DSP.sol";
import {FeeRateModel} from "../contracts/DODOStablePool/lib/FeeRateModel.sol";
import {FeeRateDIP3Impl} from "../contracts/DODOFee/FeeRateDIP3Impl.sol";

contract DeployDSP is Script {
    DSP public dsp;
    FeeRateModel public feeRateModel;
    FeeRateDIP3Impl public feeRateDIP3Impl;

    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    // Init params
    address constant MAINTAINER = 0x95C4F5b83aA70810D4f142d58e5F7242Bd891CB0;
    address constant BASE_TOKEN_ADDRESS = DAI;
    address constant QUOTE_TOKEN_ADDRESS = USDC;
    uint256 constant LP_FEE_RATE = 0;
    uint256 constant MT_FEE_RATE = 10000000000000;
    uint256 constant I = 1000000;
    uint256 constant K = 500000000000000;
    bool constant IS_OPEN_TWAP = false;

    function run() external returns(DSP) {
        deployFeeRateModel();
        dsp = new DSP();
        feeRateDIP3Impl.setSpecPoolList(address(dsp), MT_FEE_RATE);

        // init DSP
        address  MT_FEE_RATE_MODEL = address(feeRateModel);
        dsp.init(
            MAINTAINER,
            BASE_TOKEN_ADDRESS,
            QUOTE_TOKEN_ADDRESS,
            LP_FEE_RATE,
            MT_FEE_RATE_MODEL,
            I,
            K,
            IS_OPEN_TWAP
        );

        return dsp;
    }

    function deployFeeRateDIP3Impl() internal {
        feeRateDIP3Impl = new FeeRateDIP3Impl();
        feeRateDIP3Impl.initOwner(address(this));
    }

    function deployFeeRateModel() internal returns(FeeRateModel) {
        deployFeeRateDIP3Impl();

        feeRateModel = new FeeRateModel();
        feeRateModel.initOwner(address(this));
        feeRateModel.setFeeProxy(address(feeRateDIP3Impl));
        return feeRateModel;
    }

    function testSuccess() public {}
}
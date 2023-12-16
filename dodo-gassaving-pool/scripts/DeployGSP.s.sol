// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "../lib/forge-std/src/Script.sol";
import "../lib/forge-std/src/console.sol";

import {GSP} from "../contracts/GasSavingPool/impl/GSP.sol";


contract DeployGSP is Script {

    GSP public gsp;

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

    function run() public returns (GSP){
        // Deploy GSP
        gsp = new GSP();

        // init GSP
        gsp.init(
            MAINTAINER,
            BASE_TOKEN_ADDRESS,
            QUOTE_TOKEN_ADDRESS,
            LP_FEE_RATE,
            MT_FEE_RATE,
            I,
            K,
            IS_OPEN_TWAP
        );

        return gsp;
    }

    function testSuccess() public {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;
pragma abicoder v2;

import {Test, console} from "forge-std/Test.sol";
import {DeployGSP} from "../scripts/DeployGSP.s.sol";
import {GSP} from "../contracts/GasSavingPool/impl/GSP.sol";

contract TestGSPStorage is Test {
    GSP gsp;

    // Init Params
    uint256 constant i = 1000000;
    uint256 constant k = 500000000000000;


    function setUp() public {
        // Deploy and Init 
        DeployGSP deployGSP = new DeployGSP();
        gsp = deployGSP.run();
    }

    function test_getMtFeeTotal() public {
        (uint256 mtFeeBase, uint256 mtFeeQuote) = gsp.getMtFeeTotal();
        assertTrue(mtFeeBase == 0);
        assertTrue(mtFeeQuote == 0);
    }

    function test_getPMMStateForCall() public {
        (
            uint256 I,
            uint256 K,
            uint256 B,
            uint256 Q,
            uint256 B0,
            uint256 Q0,
            uint256 R
        ) = gsp.getPMMStateForCall();

        (uint256 b, uint256 q) = gsp.getVaultReserve();
        assertTrue(I == i);
        assertTrue(K == k);
        assertTrue(B == b);
        assertTrue(Q == q);
        assertTrue(B0 == 0);
        assertTrue(Q0 == 0);
        assertTrue(R == 0);
    }
}
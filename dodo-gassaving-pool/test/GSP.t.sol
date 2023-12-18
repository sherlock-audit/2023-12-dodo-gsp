// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;
pragma abicoder v2;

import {Test, console} from "forge-std/Test.sol";
import {GSP} from "../contracts/GasSavingPool/impl/GSP.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestGSPVault is Test {
    GSP gsp;

    // Test Params
    address USER = vm.addr(1);
    address OTHER = vm.addr(2);
    address constant USDC_WHALE = 0x51eDF02152EBfb338e03E30d65C15fBf06cc9ECC;
    address constant DAI_WHALE = 0x25B313158Ce11080524DcA0fD01141EeD5f94b81;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    IERC20 private usdc = IERC20(USDC);
    IERC20 private dai = IERC20(DAI);
    uint256 constant BASE_RESERVE = 1e19; // 10 DAI
    uint256 constant QUOTE_RESERVE = 1e7; // 10 USDC
    uint256 constant BASE_INPUT = 1e18; // 1 DAI
    uint256 constant QUOTE_INPUT = 2e6; // 2 USDC

    function setUp() public {
        gsp = new GSP();
    }

    function test_init() public {
        // Init params
        address MAINTAINER = 0x95C4F5b83aA70810D4f142d58e5F7242Bd891CB0;
        address BASE_TOKEN_ADDRESS = DAI;
        address QUOTE_TOKEN_ADDRESS = USDC;
        uint256 LP_FEE_RATE = 0;
        uint256 MT_FEE_RATE = 10000000000000;
        uint256 I = 1000000;
        uint256 K = 500000000000000;
        bool IS_OPEN_TWAP = false;

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

        // Check init params
        assertTrue(gsp._MAINTAINER_() == MAINTAINER);
        assertTrue(gsp._BASE_TOKEN_() == IERC20(BASE_TOKEN_ADDRESS));
        assertTrue(gsp._QUOTE_TOKEN_() == IERC20(QUOTE_TOKEN_ADDRESS));
        assertTrue(gsp._LP_FEE_RATE_() == LP_FEE_RATE);
        assertTrue(gsp._MT_FEE_RATE_() == MT_FEE_RATE);
        assertTrue(gsp._I_() == I);
        assertTrue(gsp._K_() == K);
        assertTrue(gsp._IS_OPEN_TWAP_() == IS_OPEN_TWAP);
    }

    function test_getVersion() public {
        assertEq(sha256(abi.encodePacked(gsp.version())), sha256(abi.encodePacked("GSP 1.0.1")));
    }

    function test_addressToShortString() public {
        string memory str = gsp.addressToShortString(address(gsp));
        assertEq(sha256(abi.encodePacked(str)), sha256(abi.encodePacked("5615deb7")));
    }

    function test_twapUpdate() public {
        // set is_open_twap to true
        address MAINTAINER = 0x95C4F5b83aA70810D4f142d58e5F7242Bd891CB0;
        address BASE_TOKEN_ADDRESS = DAI;
        address QUOTE_TOKEN_ADDRESS = USDC;
        uint256 LP_FEE_RATE = 0;
        uint256 MT_FEE_RATE = 10000000000000;
        uint256 I = 1000000;
        uint256 K = 500000000000000;
        bool IS_OPEN_TWAP = true;
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

        // transfer some tokens to USER
        vm.startPrank(DAI_WHALE);
        dai.transfer(USER, BASE_RESERVE + BASE_INPUT);
        vm.stopPrank();
        vm.startPrank(USDC_WHALE);
        usdc.transfer(USER, QUOTE_RESERVE + QUOTE_INPUT);
        vm.stopPrank();
        // User buys shares
        vm.startPrank(USER);
        dai.transfer(address(gsp), BASE_RESERVE);
        usdc.transfer(address(gsp), QUOTE_RESERVE);
        gsp.buyShares(USER);
        dai.transfer(address(gsp), BASE_INPUT);
        gsp.sellBase(USER);
        uint32 blockTimestampBefore = gsp._BLOCK_TIMESTAMP_LAST_();
        // Time elapse
        vm.warp(block.timestamp + 500000);
        usdc.transfer(address(gsp), QUOTE_INPUT);
        gsp.sellQuote(USER);
        uint32 blockTimestampAfter = gsp._BLOCK_TIMESTAMP_LAST_();
        vm.stopPrank();
        assertTrue(gsp._IS_OPEN_TWAP_() == true);
        assertTrue(blockTimestampAfter > blockTimestampBefore);
    }

    function test_initFail() public {
        // Init params
        address MAINTAINER = 0x95C4F5b83aA70810D4f142d58e5F7242Bd891CB0;
        address BASE_TOKEN_ADDRESS = DAI;
        address QUOTE_TOKEN_ADDRESS = USDC;
        uint256 LP_FEE_RATE = 0;
        uint256 MT_FEE_RATE = 10000000000000;
        uint256 I = 1e36; 
        uint256 K = 1e18;
        bool IS_OPEN_TWAP = false;

        vm. expectRevert("BASE_QUOTE_CAN_NOT_BE_SAME");
        gsp.init(
            MAINTAINER,
            BASE_TOKEN_ADDRESS,
            BASE_TOKEN_ADDRESS,
            LP_FEE_RATE,
            MT_FEE_RATE,
            I,
            K,
            IS_OPEN_TWAP
        );
        // I is invalid
        vm. expectRevert();
        gsp.init(
            MAINTAINER,
            BASE_TOKEN_ADDRESS,
            QUOTE_TOKEN_ADDRESS,
            LP_FEE_RATE,
            MT_FEE_RATE,
            2 * I,
            K,
            IS_OPEN_TWAP
        );
        // K is invalid
        vm. expectRevert();
        gsp.init(
            MAINTAINER,
            BASE_TOKEN_ADDRESS,
            QUOTE_TOKEN_ADDRESS,
            LP_FEE_RATE,
            MT_FEE_RATE,
            I,
            2 * K,
            IS_OPEN_TWAP
        );

        // Init twice
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
        vm.expectRevert("GSP_INITIALIZED");
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
    }
}
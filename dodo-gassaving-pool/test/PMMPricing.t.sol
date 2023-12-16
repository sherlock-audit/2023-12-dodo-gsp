// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "contracts/lib/PMMPricing.sol";

// This helper contract exposes internal library functions for coverage to pick up
// check this link: https://github.com/foundry-rs/foundry/pull/3128#issuecomment-1241245086
contract PMMPricingTestHelper {
    
    function sellBaseToken(PMMPricing.PMMState memory state, uint256 payBaseAmount)
        external
        pure
        returns (uint256, PMMPricing.RState)
    {
        (uint256 receiveQuoteAmount, PMMPricing.RState newR) = PMMPricing.sellBaseToken(state, payBaseAmount);
        return (receiveQuoteAmount, newR);
    }

    function sellQuoteToken(PMMPricing.PMMState memory state, uint256 payQuoteAmount)
        external
        pure
        returns (uint256, PMMPricing.RState)
    {
        (uint256 receiveBaseAmount, PMMPricing.RState newR) = PMMPricing.sellQuoteToken(state, payQuoteAmount);
        return (receiveBaseAmount, newR);
        
    }

    function getMidPrice(PMMPricing.PMMState memory state)
        external
        pure
        returns (uint256)
    {
        uint256 result = PMMPricing.getMidPrice(state);
        return result;
    }
}

contract PMMPricingTest is Test {
    PMMPricingTestHelper public helper;

    PMMPricing.PMMState public state;

    function setUp() public {
        helper = new PMMPricingTestHelper();
    }

    function testSellBaseToken() public {
        // case 1: R=1
        // R falls below one
        state.i = 1e18;
        state.K = 1e18;
        state.B = 5e18;
        state.Q = 5e18;
        state.B0 = 5e18;
        state.Q0 = 5e18;
        state.R = PMMPricing.RState.ONE;
        (uint256 receiveQuoteAmount, PMMPricing.RState newR) = helper.sellBaseToken(state, 1e18);
        assertTrue(newR == PMMPricing.RState.BELOW_ONE);

        // case 3: R<1
        state.B0 = 2e18;
        state.Q0 = 8e18;
        state.R = PMMPricing.RState.BELOW_ONE;
        (receiveQuoteAmount, newR) = helper.sellBaseToken(state, 1e18);
        assertTrue(newR == PMMPricing.RState.BELOW_ONE);

        // case 2: R>1
        state.B0 = 8e18;
        state.Q0 = 2e18;
        state.R = PMMPricing.RState.ABOVE_ONE;
        // case 2.1: R status do not change
        (receiveQuoteAmount, newR) = helper.sellBaseToken(state, 1e18);
        assertTrue(newR == PMMPricing.RState.ABOVE_ONE);
        // case 2.2: R status changes to ONE
        (receiveQuoteAmount, newR) = helper.sellBaseToken(state, 3e18);
        assertTrue(newR == PMMPricing.RState.ONE);
        // case 2.3: R status changes to BELOW_ONE
        (receiveQuoteAmount, newR) = helper.sellBaseToken(state, 5e18);
        assertTrue(newR == PMMPricing.RState.BELOW_ONE);
    }

    function testSellBaseTokenCornerCase() public {
        state.i = 1e18;
        state.K = 1e18;
        state.B = 5e18;
        state.Q = 5e18;
        state.B0 = 10e18;
        state.Q0 = 2e18;
        state.R = PMMPricing.RState.ABOVE_ONE;
        (uint256 receiveQuoteAmount, PMMPricing.RState newR) = helper.sellBaseToken(state, 1e18);
        assertTrue(newR == PMMPricing.RState.ABOVE_ONE);
        assertTrue(receiveQuoteAmount == state.Q - state.Q0);
    }

    function testSellQuoteToken() public {
        // case 1: R=1
        // R falls above one
        state.i = 1e18;
        state.K = 1e18;
        state.B = 5e18;
        state.Q = 5e18;
        state.B0 = 5e18;
        state.Q0 = 5e18;
        state.R = PMMPricing.RState.ONE;
        (uint256 receiveQuoteAmount, PMMPricing.RState newR) = helper.sellQuoteToken(state, 1e18);
        assertTrue(newR == PMMPricing.RState.ABOVE_ONE);

        // case 2: R>1
        // R does not change
        state.B0 = 8e18;
        state.Q0 = 2e18;
        state.R = PMMPricing.RState.ABOVE_ONE;
        (receiveQuoteAmount, newR) = helper.sellQuoteToken(state, 1e18);
        assertTrue(newR == PMMPricing.RState.ABOVE_ONE);

        // case 3: R<1
        state.B0 = 2e18;
        state.Q0 = 8e18;
        state.R = PMMPricing.RState.BELOW_ONE;
        // case 2.1: R status do not change
        (receiveQuoteAmount, newR) = helper.sellQuoteToken(state, 1e18);
        assertTrue(newR == PMMPricing.RState.BELOW_ONE);
        // case 2.2: R status changes to ONE
        (receiveQuoteAmount, newR) = helper.sellQuoteToken(state, 3e18);
        assertTrue(newR == PMMPricing.RState.ONE);
        // case 2.3: R status changes to ABOVE_ONE
        (receiveQuoteAmount, newR) = helper.sellQuoteToken(state, 5e18);
        assertTrue(newR == PMMPricing.RState.ABOVE_ONE);
    }

    function testSellQuoteTokenCornerCase() public {
        state.i = 1e18;
        state.K = 1e18;
        state.B = 5e18;
        state.Q = 5e18;
        state.B0 = 2e18;
        state.Q0 = 10e18;
        state.R = PMMPricing.RState.BELOW_ONE;
        (uint256 receiveBaseAmount, PMMPricing.RState newR) = helper.sellQuoteToken(state, 1e18);
        assertTrue(newR == PMMPricing.RState.BELOW_ONE);
        assertTrue(receiveBaseAmount == state.B - state.B0);
    }

    function testGetMidPrice() public {
        state.i = 1e18;
        state.K = 1e18;
        state.B = 5e18;
        state.Q = 5e18;
        state.B0 = 6e18;
        state.Q0 = 6e18;
        uint256 midPrice;
        state.R = PMMPricing.RState.BELOW_ONE;
        midPrice = helper.getMidPrice(state);
        assertEq(midPrice, 694444444444444444);
    }
}
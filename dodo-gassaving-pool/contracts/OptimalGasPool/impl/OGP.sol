// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

import {IERC20} from "../../DODOStablePool/intf/IERC20.sol";
import {SafeMath} from "../../DODOStablePool/lib/SafeMath.sol";
import {SafeERC20} from "../../DODOStablePool/lib/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OGP is ReentrancyGuard{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public _BASE_RESERVE_;
    uint256 public _QUOTE_RESERVE_;
    
    // DAI - USDC
    IERC20 constant _BASE_TOKEN_ = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 constant _QUOTE_TOKEN_ = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    // X + Y = K
    uint256 constant _K_ = 4; // 

    function sync() external {
        _BASE_RESERVE_= _BASE_TOKEN_.balanceOf(address(this));
        _QUOTE_RESERVE_ = _QUOTE_TOKEN_.balanceOf(address(this)); 
    }

    function sellBase(address to) external nonReentrant returns (uint256 receiveQuoteAmount) {
        uint256 baseBalance = _BASE_TOKEN_.balanceOf(address(this));

        receiveQuoteAmount = _K_.sub(baseBalance.div(1e18)).mul(1e6);
        _QUOTE_TOKEN_.safeTransfer(to, receiveQuoteAmount);
        _BASE_RESERVE_ = baseBalance;
        _QUOTE_RESERVE_ = _QUOTE_TOKEN_.balanceOf(address(this));
    }

    function sellQuote(address to) external nonReentrant returns (uint256 receiveBaseAmount) {
        uint256 quoteBalance = _QUOTE_TOKEN_.balanceOf(address(this));

        receiveBaseAmount = _K_.sub(quoteBalance.div(1e6)).mul(1e18);
        _BASE_TOKEN_.safeTransfer(to, receiveBaseAmount);
        _BASE_RESERVE_ = _BASE_TOKEN_.balanceOf(address(this));
        _QUOTE_RESERVE_ = quoteBalance;
    }

}
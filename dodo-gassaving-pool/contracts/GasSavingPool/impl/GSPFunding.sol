/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/


pragma solidity 0.8.16;

import {GSPVault} from "./GSPVault.sol";
import {DecimalMath} from "../../lib/DecimalMath.sol";
import {IDODOCallee} from "../../intf/IDODOCallee.sol";

/// @notice this part focus on Lp tokens, mint and burn
contract GSPFunding is GSPVault {
    // ============ Events ============

    event BuyShares(address to, uint256 increaseShares, uint256 totalShares);

    event SellShares(address payer, address to, uint256 decreaseShares, uint256 totalShares);

    // ============ Buy & Sell Shares ============
    
    /// @notice User mint Lp token and deposit tokens, the result is rounded down
    /// @dev User first transfer baseToken and quoteToken to GSP, then call buyShares
    /// @param to The address will receive shares
    /// @return shares The amount of shares user will receive
    /// @return baseInput The amount of baseToken user transfer to GSP
    /// @return quoteInput The amount of quoteToken user transfer to GSP
    function buyShares(address to)
        external
        nonReentrant
        returns (
            uint256 shares,
            uint256 baseInput,
            uint256 quoteInput
        )
    {
        // The balance of baseToken and quoteToken should be the balance minus the fee
        uint256 baseBalance = _BASE_TOKEN_.balanceOf(address(this)) - _MT_FEE_BASE_;
        uint256 quoteBalance = _QUOTE_TOKEN_.balanceOf(address(this)) - _MT_FEE_QUOTE_;
        // The reserve of baseToken and quoteToken
        uint256 baseReserve = _BASE_RESERVE_;
        uint256 quoteReserve = _QUOTE_RESERVE_;

        // The amount of baseToken and quoteToken user transfer to GSP
        baseInput = baseBalance - baseReserve;
        quoteInput = quoteBalance - quoteReserve;

        // BaseToken should be transferred to GSP before calling buyShares
        require(baseInput > 0, "NO_BASE_INPUT");

        // Round down when withdrawing. Therefore, never be a situation occuring balance is 0 but totalsupply is not 0
        // But May Happen，reserve >0 But totalSupply = 0
        if (totalSupply == 0) {
            // case 1. initial supply
            // The shares will be minted to user
            shares = quoteBalance < DecimalMath.mulFloor(baseBalance, _I_)
                ? DecimalMath.divFloor(quoteBalance, _I_)
                : baseBalance;
            // The target will be updated
            _BASE_TARGET_ = uint112(shares);
            _QUOTE_TARGET_ = uint112(DecimalMath.mulFloor(shares, _I_));
        } else if (baseReserve > 0 && quoteReserve > 0) {
            // case 2. normal case
            uint256 baseInputRatio = DecimalMath.divFloor(baseInput, baseReserve);
            uint256 quoteInputRatio = DecimalMath.divFloor(quoteInput, quoteReserve);
            uint256 mintRatio = quoteInputRatio < baseInputRatio ? quoteInputRatio : baseInputRatio;
            // The shares will be minted to user
            shares = DecimalMath.mulFloor(totalSupply, mintRatio);

            // The target will be updated
            _BASE_TARGET_ = uint112(uint256(_BASE_TARGET_) + (DecimalMath.mulFloor(uint256(_BASE_TARGET_), mintRatio)));
            _QUOTE_TARGET_ = uint112(uint256(_QUOTE_TARGET_) + (DecimalMath.mulFloor(uint256(_QUOTE_TARGET_), mintRatio)));
        }
        // The shares will be minted to user
        // The reserve will be updated
        _mint(to, shares);
        _setReserve(baseBalance, quoteBalance);
        emit BuyShares(to, shares, _SHARES_[to]);
    }

    /// @notice User burn their lp and withdraw their tokens, the result is rounded down
    /// @dev User call sellShares, the calculated baseToken and quoteToken amount should geater than minBaseToken and minQuoteToken
    /// @param shareAmount The amount of shares user want to sell
    /// @param to The address will receive baseToken and quoteToken
    /// @param baseMinAmount The minimum amount of baseToken user want to receive
    /// @param quoteMinAmount The minimum amount of quoteToken user want to receive
    /// @param data The data will be passed to callee contract
    /// @param deadline The deadline of this transaction
    function sellShares(
        uint256 shareAmount,
        address to,
        uint256 baseMinAmount,
        uint256 quoteMinAmount,
        bytes calldata data,
        uint256 deadline
    ) external nonReentrant returns (uint256 baseAmount, uint256 quoteAmount) {
        // The deadline should be greater than current timestamp
        require(deadline >= block.timestamp, "TIME_EXPIRED");
        // The amount of shares user want to sell should be less than user's balance
        require(shareAmount <= _SHARES_[msg.sender], "GLP_NOT_ENOUGH");

        // The balance of baseToken and quoteToken should be the balance minus the fee
        uint256 baseBalance = _BASE_TOKEN_.balanceOf(address(this)) - _MT_FEE_BASE_;
        uint256 quoteBalance = _QUOTE_TOKEN_.balanceOf(address(this)) - _MT_FEE_QUOTE_;
        // The total shares of GSP
        uint256 totalShares = totalSupply;

        // The amount of baseToken and quoteToken user will receive is calculated by the ratio of user's shares to total shares
        baseAmount = baseBalance * shareAmount / totalShares;
        quoteAmount = quoteBalance * shareAmount / totalShares;
        
        // The target will be updated
        _BASE_TARGET_ = uint112(uint256(_BASE_TARGET_) - DecimalMath._divCeil((uint256(_BASE_TARGET_) * (shareAmount)), totalShares));
        _QUOTE_TARGET_ = uint112(uint256(_QUOTE_TARGET_) - DecimalMath._divCeil((uint256(_QUOTE_TARGET_) * (shareAmount)), totalShares));
        
        // The calculated baseToken and quoteToken amount should geater than minBaseToken and minQuoteToken
        require(
            baseAmount >= baseMinAmount && quoteAmount >= quoteMinAmount,
            "WITHDRAW_NOT_ENOUGH"
        );

        // The shares will be burned from user
        // The baseToken and quoteToken will be transferred to user
        // The reserve will be synced
        _burn(msg.sender, shareAmount);
        _transferBaseOut(to, baseAmount);
        _transferQuoteOut(to, quoteAmount);
        _sync();

        // If the data is not empty, the callee contract will be called
        if (data.length > 0) {
            //Same as DVM 
            IDODOCallee(to).DVMSellShareCall(
                msg.sender,
                shareAmount,
                baseAmount,
                quoteAmount,
                data
            );
        }

        emit SellShares(msg.sender, to, shareAmount, _SHARES_[msg.sender]);
    }
}

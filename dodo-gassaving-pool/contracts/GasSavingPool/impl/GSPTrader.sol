/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

import {GSPVault} from "./GSPVault.sol";
import {DecimalMath} from "../../lib/DecimalMath.sol";
import {PMMPricing} from "../../lib/PMMPricing.sol";
import {IDODOCallee} from "../../intf/IDODOCallee.sol";

/// @notice this contract deal with swap
contract GSPTrader is GSPVault {

    // ============ Events ============

    event DODOSwap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address trader,
        address receiver
    );

    event DODOFlashLoan(address borrower, address assetTo, uint256 baseAmount, uint256 quoteAmount);

    event RChange(PMMPricing.RState newRState);

    // ============ Trade Functions ============
    /**
     * @notice User sell base tokens, user pay tokens first. Must be used with a router
     * @dev The base token balance is the actual balance minus the mt fee
     * @param to The recipient of the output
     * @return receiveQuoteAmount Amount of quote token received
     */
    function sellBase(address to) external nonReentrant returns (uint256 receiveQuoteAmount) {
        uint256 baseBalance = _BASE_TOKEN_.balanceOf(address(this)) - _MT_FEE_BASE_;
        uint256 baseInput = baseBalance - uint256(_BASE_RESERVE_);
        uint256 mtFee;
        uint256 newBaseTarget;
        PMMPricing.RState newRState;
        // calculate the amount of quote token to receive and mt fee
        (receiveQuoteAmount, mtFee, newRState, newBaseTarget) = querySellBase(tx.origin, baseInput);
        // transfer quote token to recipient
        _transferQuoteOut(to, receiveQuoteAmount);
        // update mt fee in quote token
        _MT_FEE_QUOTE_ = _MT_FEE_QUOTE_ + mtFee;
        

        // update TARGET
        if (_RState_ != uint32(newRState)) {    
            require(newBaseTarget <= type(uint112).max, "OVERFLOW");
            _BASE_TARGET_ = uint112(newBaseTarget);
            _RState_ = uint32(newRState);
            emit RChange(newRState);
        }
        // update reserve
        _setReserve(baseBalance, _QUOTE_TOKEN_.balanceOf(address(this)) - _MT_FEE_QUOTE_);

        emit DODOSwap(
            address(_BASE_TOKEN_),
            address(_QUOTE_TOKEN_),
            baseInput,
            receiveQuoteAmount,
            msg.sender,
            to
        );
    }

    /**
     * @notice User sell quote tokens, user pay tokens first. Must be used with a router
     * @param to The recipient of the output
     * @return receiveBaseAmount Amount of base token received
     */
    function sellQuote(address to) external nonReentrant returns (uint256 receiveBaseAmount) {
        uint256 quoteBalance = _QUOTE_TOKEN_.balanceOf(address(this)) - _MT_FEE_QUOTE_;
        uint256 quoteInput = quoteBalance - uint256(_QUOTE_RESERVE_);
        uint256 mtFee;
        uint256 newQuoteTarget;
        PMMPricing.RState newRState;
        // calculate the amount of base token to receive and mt fee
        (receiveBaseAmount, mtFee, newRState, newQuoteTarget) = querySellQuote(
            tx.origin,
            quoteInput
        );
        // transfer base token to recipient
        _transferBaseOut(to, receiveBaseAmount);
        // update mt fee in base token
        _MT_FEE_BASE_ = _MT_FEE_BASE_ + mtFee;

        // update TARGET
        if (_RState_ != uint32(newRState)) {
            require(newQuoteTarget <= type(uint112).max, "OVERFLOW");
            _QUOTE_TARGET_ = uint112(newQuoteTarget);
            _RState_ = uint32(newRState);
            emit RChange(newRState);
        }
        // update reserve
        _setReserve((_BASE_TOKEN_.balanceOf(address(this)) - _MT_FEE_BASE_), quoteBalance);

        emit DODOSwap(
            address(_QUOTE_TOKEN_),
            address(_BASE_TOKEN_),
            quoteInput,
            receiveBaseAmount,
            msg.sender,
            to
        );
    }

    /**
     * @notice inner flashloan, pay tokens out first, call external contract and check tokens left
     * @param baseAmount The base token amount user require
     * @param quoteAmount The quote token amount user require
     * @param assetTo The address who uses above tokens
     * @param data The external contract's callData
     */
    function flashLoan(
        uint256 baseAmount,
        uint256 quoteAmount,
        address assetTo,
        bytes calldata data
    ) external nonReentrant {
        _transferBaseOut(assetTo, baseAmount);
        _transferQuoteOut(assetTo, quoteAmount);

        if (data.length > 0)
            IDODOCallee(assetTo).DSPFlashLoanCall(msg.sender, baseAmount, quoteAmount, data);

        uint256 baseBalance = _BASE_TOKEN_.balanceOf(address(this)) - _MT_FEE_BASE_;
        uint256 quoteBalance = _QUOTE_TOKEN_.balanceOf(address(this)) - _MT_FEE_QUOTE_;

        // no input -> pure loss
        require(
            baseBalance >= _BASE_RESERVE_ || quoteBalance >= _QUOTE_RESERVE_,
            "FLASH_LOAN_FAILED"
        );

        // sell quote case
        // quote input + base output
        if (baseBalance < _BASE_RESERVE_) {
            uint256 quoteInput = quoteBalance - uint256(_QUOTE_RESERVE_);
            (
                uint256 receiveBaseAmount,
                uint256 mtFee,
                PMMPricing.RState newRState,
                uint256 newQuoteTarget
            ) = querySellQuote(tx.origin, quoteInput); // revert if quoteBalance<quoteReserve
            require(
                (uint256(_BASE_RESERVE_) - baseBalance) <= receiveBaseAmount,
                "FLASH_LOAN_FAILED"
            );
            
            _MT_FEE_BASE_ = _MT_FEE_BASE_ + mtFee;
            
            if (_RState_ != uint32(newRState)) {
                require(newQuoteTarget <= type(uint112).max, "OVERFLOW");
                _QUOTE_TARGET_ = uint112(newQuoteTarget);
                _RState_ = uint32(newRState);
                emit RChange(newRState);
            }
            emit DODOSwap(
                address(_QUOTE_TOKEN_),
                address(_BASE_TOKEN_),
                quoteInput,
                receiveBaseAmount,
                msg.sender,
                assetTo
            );
        }

        // sell base case
        // base input + quote output
        if (quoteBalance < _QUOTE_RESERVE_) {
            uint256 baseInput = baseBalance - uint256(_BASE_RESERVE_);
            (
                uint256 receiveQuoteAmount,
                uint256 mtFee,
                PMMPricing.RState newRState,
                uint256 newBaseTarget
            ) = querySellBase(tx.origin, baseInput); // revert if baseBalance<baseReserve
            require(
                (uint256(_QUOTE_RESERVE_) - quoteBalance) <= receiveQuoteAmount,
                "FLASH_LOAN_FAILED"
            );

            _MT_FEE_QUOTE_ = _MT_FEE_QUOTE_ + mtFee;
            
            if (_RState_ != uint32(newRState)) {
                require(newBaseTarget <= type(uint112).max, "OVERFLOW");
                _BASE_TARGET_ = uint112(newBaseTarget);
                _RState_ = uint32(newRState);
                emit RChange(newRState);
            }
            emit DODOSwap(
                address(_BASE_TOKEN_),
                address(_QUOTE_TOKEN_),
                baseInput,
                receiveQuoteAmount,
                msg.sender,
                assetTo
            );
        }

        _sync();

        emit DODOFlashLoan(msg.sender, assetTo, baseAmount, quoteAmount);
    }

    // ============ Query Functions ============
    /**
     * @notice Return swap result, for query, sellBase side. 
     * @param trader Useless, just to keep the same interface with old version pool
     * @param payBaseAmount The amount of base token user want to sell
     * @return receiveQuoteAmount The amount of quote token user will receive
     * @return mtFee The amount of mt fee charged
     * @return newRState The new RState after swap
     * @return newBaseTarget The new base target after swap
     */
    function querySellBase(address trader, uint256 payBaseAmount)
        public
        view
        returns (
            uint256 receiveQuoteAmount,
            uint256 mtFee,
            PMMPricing.RState newRState,
            uint256 newBaseTarget
        )
    {
        PMMPricing.PMMState memory state = getPMMState();
        (receiveQuoteAmount, newRState) = PMMPricing.sellBaseToken(state, payBaseAmount);

        uint256 lpFeeRate = _LP_FEE_RATE_;
        uint256 mtFeeRate = _MT_FEE_RATE_;
        mtFee = DecimalMath.mulFloor(receiveQuoteAmount, mtFeeRate);
        receiveQuoteAmount = receiveQuoteAmount
            - DecimalMath.mulFloor(receiveQuoteAmount, lpFeeRate)
            - mtFee;
        newBaseTarget = state.B0;
    }
    /**
     * @notice Return swap result, for query, sellQuote side
     * @param trader Useless, just for keeping the same interface with old version pool
     * @param payQuoteAmount The amount of quote token user want to sell
     * @return receiveBaseAmount The amount of base token user will receive
     * @return mtFee The amount of mt fee charged
     * @return newRState The new RState after swap
     * @return newQuoteTarget The new quote target after swap
     */
    function querySellQuote(address trader, uint256 payQuoteAmount)
        public
        view
        returns (
            uint256 receiveBaseAmount,
            uint256 mtFee,
            PMMPricing.RState newRState,
            uint256 newQuoteTarget
        )
    {
        PMMPricing.PMMState memory state = getPMMState();
        (receiveBaseAmount, newRState) = PMMPricing.sellQuoteToken(state, payQuoteAmount);

        uint256 lpFeeRate = _LP_FEE_RATE_;
        uint256 mtFeeRate = _MT_FEE_RATE_;
        mtFee = DecimalMath.mulFloor(receiveBaseAmount, mtFeeRate);
        receiveBaseAmount = receiveBaseAmount
            - DecimalMath.mulFloor(receiveBaseAmount, lpFeeRate)
            - mtFee;
        newQuoteTarget = state.Q0;
    }
}

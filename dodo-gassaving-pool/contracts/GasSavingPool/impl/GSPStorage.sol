/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

import {DODOMath} from "../../lib/DODOMath.sol";
import {DecimalMath} from "../../lib/DecimalMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {PMMPricing} from "../../lib/PMMPricing.sol";

/// @notice this contract is used for store state and read state
contract GSPStorage is ReentrancyGuard {

    // ============ Storage for Setup ============
    // _GSP_INITIALIZED_ will be set to true when the init function is called
    bool internal _GSP_INITIALIZED_;
    // GSP does not open TWAP by default
    // _IS_OPEN_TWAP_ can be set to true when the init function is called
    bool public _IS_OPEN_TWAP_ = false;
    
    // ============ Core Address ============
    // _MAINTAINER_ is the maintainer of GSP
    address public _MAINTAINER_;
    // _BASE_TOKEN_ and _QUOTE_TOKEN_ should be ERC20 token
    IERC20 public _BASE_TOKEN_;
    IERC20 public _QUOTE_TOKEN_;
    // _BASE_RESERVE_ and _QUOTE_RESERVE_ are the current reserves of the GSP
    uint112 public _BASE_RESERVE_;
    uint112 public _QUOTE_RESERVE_;
    // _BLOCK_TIMESTAMP_LAST_ is used when calculating TWAP
    uint32 public _BLOCK_TIMESTAMP_LAST_;
    // _BASE_PRICE_CUMULATIVE_LAST_ is used when calculating TWAP
    uint256 public _BASE_PRICE_CUMULATIVE_LAST_;

    // _BASE_TARGET_ and _QUOTE_TARGET_ are recalculated when the pool state changes
    uint112 public _BASE_TARGET_;
    uint112 public _QUOTE_TARGET_;
    // _RState_ is the current R state of the GSP
    uint32 public _RState_;

    // ============ Shares (ERC20) ============
    // symbol is the symbol of the shares
    string public symbol;
    // decimals is the decimals of the shares
    uint8 public decimals;
    // name is the name of the shares
    string public name;
    // totalSupply is the total supply of the shares
    uint256 public totalSupply;
    // _SHARES_ is the mapping from account to share balance, record the share balance of each account
    mapping(address => uint256) internal _SHARES_;
    mapping(address => mapping(address => uint256)) internal _ALLOWED_;

    // ================= Permit ======================

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    // ============ Variables for Pricing ============
    // _MT_FEE_RATE_ is the fee rate of mt fee
    uint256 public _MT_FEE_RATE_;
    // _LP_FEE_RATE_ is the fee rate of lp fee
    uint256 public _LP_FEE_RATE_;
    uint256 public _K_;
    uint256 public _I_;
    // _PRICE_LIMIT_ is 1/1000 by default, which is used to limit the setting range of I
    uint256 public _PRICE_LIMIT_ = 1e3;

    // ============ Mt Fee ============
    // _MT_FEE_BASE_ represents the mt fee in base token
    uint256 public _MT_FEE_BASE_;
    // _MT_FEE_QUOTE_ represents the mt fee in quote token
    uint256 public _MT_FEE_QUOTE_;

    // ============ Helper Functions ============

    /// @notice Return the PMM state of the pool from inner or outside
    /// @dev B0 and Q0 are calculated in adjustedTarget
    /// @return state The current PMM state
    function getPMMState() public view returns (PMMPricing.PMMState memory state) {
        state.i = _I_;
        state.K = _K_;
        state.B = _BASE_RESERVE_;
        state.Q = _QUOTE_RESERVE_;
        state.B0 = _BASE_TARGET_; // will be calculated in adjustedTarget
        state.Q0 = _QUOTE_TARGET_;
        state.R = PMMPricing.RState(_RState_);
        PMMPricing.adjustedTarget(state);
    }

    /// @notice Return the PMM state variables used for routeHelpers
    /// @return i The price index
    /// @return K The K value
    /// @return B The base token reserve
    /// @return Q The quote token reserve
    /// @return B0 The base token target
    /// @return Q0 The quote token target
    /// @return R The R state of the pool
    function getPMMStateForCall()
        external
        view
        returns (
            uint256 i,
            uint256 K,
            uint256 B,
            uint256 Q,
            uint256 B0,
            uint256 Q0,
            uint256 R
        )
    {
        PMMPricing.PMMState memory state = getPMMState();
        i = state.i;
        K = state.K;
        B = state.B;
        Q = state.Q;
        B0 = state.B0;
        Q0 = state.Q0;
        R = uint256(state.R);
    }

    /// @notice Return the adjusted mid price
    /// @return midPrice The current mid price
    function getMidPrice() public view returns (uint256 midPrice) {
        return PMMPricing.getMidPrice(getPMMState());
    }

    /// @notice Return the total mt fee maintainer can claim
    /// @dev The total mt fee is represented in two types: in base token and in quote token
    /// @return mtFeeBase The total mt fee in base token
    /// @return mtFeeQuote The total mt fee in quote token
    function getMtFeeTotal() public view returns (uint256 mtFeeBase, uint256 mtFeeQuote) {
        mtFeeBase = _MT_FEE_BASE_;
        mtFeeQuote = _MT_FEE_QUOTE_;
    }
}

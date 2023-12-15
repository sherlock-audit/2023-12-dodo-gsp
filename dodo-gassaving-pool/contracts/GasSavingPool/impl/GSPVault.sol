/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

import {DecimalMath} from "../../lib/DecimalMath.sol";
import {PMMPricing} from "../../lib/PMMPricing.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {GSPStorage} from "./GSPStorage.sol";

contract GSPVault is GSPStorage {
    using SafeERC20 for IERC20;

    // ============ Modifiers ============

    modifier onlyMaintainer() {
        require(msg.sender == _MAINTAINER_, "ACCESS_DENIED");
        _;
    }

    // ============ Events ============

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Mint(address indexed user, uint256 value);

    event Burn(address indexed user, uint256 value);

    // ============ View Functions ============

    function getVaultReserve() external view returns (uint256 baseReserve, uint256 quoteReserve) {
        baseReserve = _BASE_RESERVE_;
        quoteReserve = _QUOTE_RESERVE_;
    }

    function getUserFeeRate(address user) 
        external 
        view 
        returns (uint256 lpFeeRate, uint256 mtFeeRate) 
    {
        lpFeeRate = _LP_FEE_RATE_;
        mtFeeRate = _MT_FEE_RATE_;
    }

    // ============ Asset In ============

    function getBaseInput() public view returns (uint256 input) {
        return _BASE_TOKEN_.balanceOf(address(this)) - uint256(_BASE_RESERVE_) - uint256(_MT_FEE_BASE_);
    }

    function getQuoteInput() public view returns (uint256 input) {
        return _QUOTE_TOKEN_.balanceOf(address(this)) - uint256(_QUOTE_RESERVE_) - uint256(_MT_FEE_QUOTE_);
    }

    // ============ TWAP UPDATE ===========

    function _twapUpdate() internal {
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - _BLOCK_TIMESTAMP_LAST_;
        if (timeElapsed > 0 && _BASE_RESERVE_ != 0 && _QUOTE_RESERVE_ != 0) {
            _BASE_PRICE_CUMULATIVE_LAST_ += getMidPrice() * timeElapsed;
        }
        _BLOCK_TIMESTAMP_LAST_ = blockTimestamp;
    }

    // ============ Set States ============

    function _setReserve(uint256 baseReserve, uint256 quoteReserve) internal {
        require(baseReserve <= type(uint112).max && quoteReserve <= type(uint112).max, "OVERFLOW");
        _BASE_RESERVE_ = uint112(baseReserve);
        _QUOTE_RESERVE_ = uint112(quoteReserve);

        if (_IS_OPEN_TWAP_) _twapUpdate();
    }

    function _sync() internal {
        uint256 baseBalance = _BASE_TOKEN_.balanceOf(address(this)) - uint256(_MT_FEE_BASE_);
        uint256 quoteBalance = _QUOTE_TOKEN_.balanceOf(address(this)) - uint256(_MT_FEE_QUOTE_);
        require(baseBalance <= type(uint112).max && quoteBalance <= type(uint112).max, "OVERFLOW");
        if (baseBalance != _BASE_RESERVE_) {
            _BASE_RESERVE_ = uint112(baseBalance);
        }
        if (quoteBalance != _QUOTE_RESERVE_) {
            _QUOTE_RESERVE_ = uint112(quoteBalance);
        }

        if (_IS_OPEN_TWAP_) _twapUpdate();
    }

    function sync() external nonReentrant {
        _sync();
    }

    function correctRState() public {
        if (_RState_ == uint32(PMMPricing.RState.BELOW_ONE) && _BASE_RESERVE_<_BASE_TARGET_) {
          _RState_ = uint32(PMMPricing.RState.ONE);
          _BASE_TARGET_ = _BASE_RESERVE_;
          _QUOTE_TARGET_ = _QUOTE_RESERVE_;
        }
        if (_RState_ == uint32(PMMPricing.RState.ABOVE_ONE) && _QUOTE_RESERVE_<_QUOTE_TARGET_) {
          _RState_ = uint32(PMMPricing.RState.ONE);
          _BASE_TARGET_ = _BASE_RESERVE_;
          _QUOTE_TARGET_ = _QUOTE_RESERVE_;
        }
    }

    function adjustPriceLimit(uint256 priceLimit) external onlyMaintainer {
        // the default priceLimit is 1e3
        require(priceLimit <= 1e6, "INVALID_PRICE_LIMIT");
        _PRICE_LIMIT_ = priceLimit;
    }

    function adjustPrice(uint256 i) external onlyMaintainer {
        // the difference between i and _I_ should be less than priceLimit
        uint256 offset = i > _I_ ? i - _I_ : _I_ - i;
        require((offset * 1e6 / _I_) <= _PRICE_LIMIT_, "EXCEED_PRICE_LIMIT");
        _I_ = i;
    }

    function adjustMtFeeRate(uint256 mtFeeRate) external onlyMaintainer {
        require(mtFeeRate <= 10**18, "INVALID_MT_FEE_RATE");
        _MT_FEE_RATE_ = mtFeeRate;
    }

    // ============ Asset Out ============

    function _transferBaseOut(address to, uint256 amount) internal {
        if (amount > 0) {
            _BASE_TOKEN_.safeTransfer(to, amount);
        }
    }

    function _transferQuoteOut(address to, uint256 amount) internal {
        if (amount > 0) {
            _QUOTE_TOKEN_.safeTransfer(to, amount);
        }
    }

    function withdrawMtFeeTotal() external nonReentrant onlyMaintainer {
        uint256 mtFeeQuote = _MT_FEE_QUOTE_;
        uint256 mtFeeBase = _MT_FEE_BASE_;
        _MT_FEE_QUOTE_ = 0;
        _transferQuoteOut(_MAINTAINER_, mtFeeQuote);
        _MT_FEE_BASE_ = 0;
        _transferBaseOut(_MAINTAINER_, mtFeeBase);
    }

    // ============ Shares (ERC20) ============

    /**
     * @dev transfer token for a specified address
     * @param to The address to transfer to.
     * @param amount The amount to be transferred.
     */
    function transfer(address to, uint256 amount) public returns (bool) {
        require(amount <= _SHARES_[msg.sender], "BALANCE_NOT_ENOUGH");

        _SHARES_[msg.sender] = _SHARES_[msg.sender] - (amount);
        _SHARES_[to] = _SHARES_[to] + amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the the balance of.
     * @return balance An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) external view returns (uint256 balance) {
        return _SHARES_[owner];
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param amount uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(amount <= _SHARES_[from], "BALANCE_NOT_ENOUGH");
        require(amount <= _ALLOWED_[from][msg.sender], "ALLOWANCE_NOT_ENOUGH");

        _SHARES_[from] = _SHARES_[from] - amount;
        _SHARES_[to] = _SHARES_[to] + amount;
        _ALLOWED_[from][msg.sender] = _ALLOWED_[from][msg.sender] - amount;
        emit Transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param spender The address which will spend the funds.
     * @param amount The amount of tokens to be spent.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        _ALLOWED_[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Function to check the amount of tokens that an owner _ALLOWED_ to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _ALLOWED_[owner][spender];
    }

    function _mint(address user, uint256 value) internal {
        require(value > 1000, "MINT_AMOUNT_NOT_ENOUGH");
        _SHARES_[user] = _SHARES_[user] + value;
        totalSupply = totalSupply + value;
        emit Mint(user, value);
        emit Transfer(address(0), user, value);
    }

    function _burn(address user, uint256 value) internal {
        _SHARES_[user] = _SHARES_[user] - value;
        totalSupply = totalSupply - value;
        emit Burn(user, value);
        emit Transfer(user, address(0), value);
    }

    // ============================ Permit ======================================

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "DODO_DSP_LP: EXPIRED");
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner,
                            spender,
                            value,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );

        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "DODO_DSP_LP: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }
}
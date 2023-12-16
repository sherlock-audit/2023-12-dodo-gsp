// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

interface IOGP {
    function _BASE_RESERVE_() external view returns (uint256);

    function _QUOTE_RESERVE_() external view returns (uint256);

    function _BASE_TOKEN_() external view returns (address);

    function _QUOTE_TOKEN_() external view returns (address);

    function _K_() external view returns (uint256);

    function sync() external;

    function sellBase(address to) external returns (uint256);

    function sellQuote(address to) external returns (uint256);
}
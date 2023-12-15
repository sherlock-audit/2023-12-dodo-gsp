/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {GSPTrader} from "./GSPTrader.sol";
import {GSPFunding} from "./GSPFunding.sol";
import {GSPVault} from "./GSPVault.sol";

/**
 * @title DODO StablePool
 * @author DODO Breeder
 *
 * @notice DODOStablePool initialization
 */
contract GSP is GSPTrader, GSPFunding {
    function init(
        address maintainer,
        address baseTokenAddress,
        address quoteTokenAddress,
        uint256 lpFeeRate,
        uint256 mtFeeRate,
        uint256 i,
        uint256 k,
        bool isOpenTWAP
    ) external {
        require(!_GSP_INITIALIZED_, "GSP_INITIALIZED");
        _GSP_INITIALIZED_ = true;
        
        require(baseTokenAddress != quoteTokenAddress, "BASE_QUOTE_CAN_NOT_BE_SAME");
        _BASE_TOKEN_ = IERC20(baseTokenAddress);
        _QUOTE_TOKEN_ = IERC20(quoteTokenAddress);

        require(i > 0 && i <= 10**36);
        _I_ = i;

        require(k <= 10**18);
        _K_ = k;

        _LP_FEE_RATE_ = lpFeeRate;
        _MT_FEE_RATE_ = mtFeeRate;
        _MAINTAINER_ = maintainer;

        _IS_OPEN_TWAP_ = isOpenTWAP;
        if (isOpenTWAP) _BLOCK_TIMESTAMP_LAST_ = uint32(block.timestamp % 2**32);

        string memory connect = "_";
        string memory suffix = "GSP";

        name = string(abi.encodePacked(suffix, connect, addressToShortString(address(this))));
        symbol = "GSP";
        decimals = IERC20Metadata(baseTokenAddress).decimals();

        // ============================== Permit ====================================
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                // keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
        // ==========================================================================
    }

    function addressToShortString(address _addr) public pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(8);
        for (uint256 i = 0; i < 4; i++) {
            str[i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[1 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    // ============ Version Control ============

    function version() external pure returns (string memory) {
        return "GSP 1.0.1";
    }
}

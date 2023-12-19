
# DODO GSP contest details

- Join [Sherlock Discord](https://discord.gg/MABEWyASkp)
- Submit findings using the issue page in your private contest repo (label issues as med or high)
- [Read for more details](https://docs.sherlock.xyz/audits/watsons)

# Q&A

### Q: On what chains are the smart contracts going to be deployed?
Ethereum, Arbitrum, Aurora, Avalanche, BSC, Base, Boba, Conflux, Goerli Testnet, Linea, Manta, Mantle, MoonRiver, OKChain, Optimism, Polygon, Scroll, X1 Testnet
___

### Q: Which ERC20 tokens do you expect will interact with the smart contracts? 
stablecoin, such as USDC and USDT etc.
___

### Q: Which ERC721 tokens do you expect will interact with the smart contracts? 
none
___

### Q: Do you plan to support ERC1155?
not
___

### Q: Which ERC777 tokens do you expect will interact with the smart contracts? 
none
___

### Q: Are there any FEE-ON-TRANSFER tokens interacting with the smart contracts?

none
___

### Q: Are there any REBASING tokens interacting with the smart contracts?

none
___

### Q: Are the admins of the protocols your contracts integrate with (if any) TRUSTED or RESTRICTED?
TRUSTED 
___

### Q: Is the admin/owner of the protocol/contracts TRUSTED or RESTRICTED?
TRUSTED 
___

### Q: Are there any additional protocol roles? If yes, please explain in detail:
none
___

### Q: Is the code/contract expected to comply with any EIPs? Are there specific assumptions around adhering to those EIPs that Watsons should be aware of?
none
___

### Q: Please list any known issues/acceptable risks that should not result in a valid finding.
none
___

### Q: Please provide links to previous audits (if any).
none
___

### Q: Are there any off-chain mechanisms or off-chain procedures for the protocol (keeper bots, input validation expectations, etc)?
none
___

### Q: In case of external protocol integrations, are the risks of external contracts pausing or executing an emergency withdrawal acceptable? If not, Watsons will submit issues related to these situations that can harm your protocol's functionality.
acceptable
___

### Q: Do you expect to use any of the following tokens with non-standard behaviour with the smart contracts?
Missing Return Values, Upgradable Tokens, Tokens with Blocklists

___

### Q: Add links to relevant protocol resources
none
___



# Audit scope


[dodo-gassaving-pool @ 175cbb01a2867c79daa178c5d2d03e52bcbcb2de](https://github.com/DODOEX/dodo-gassaving-pool/tree/175cbb01a2867c79daa178c5d2d03e52bcbcb2de)
- [dodo-gassaving-pool/contracts/GasSavingPool/impl/GSP.sol](dodo-gassaving-pool/contracts/GasSavingPool/impl/GSP.sol)
- [dodo-gassaving-pool/contracts/GasSavingPool/impl/GSPFunding.sol](dodo-gassaving-pool/contracts/GasSavingPool/impl/GSPFunding.sol)
- [dodo-gassaving-pool/contracts/GasSavingPool/impl/GSPStorage.sol](dodo-gassaving-pool/contracts/GasSavingPool/impl/GSPStorage.sol)
- [dodo-gassaving-pool/contracts/GasSavingPool/impl/GSPTrader.sol](dodo-gassaving-pool/contracts/GasSavingPool/impl/GSPTrader.sol)
- [dodo-gassaving-pool/contracts/GasSavingPool/impl/GSPVault.sol](dodo-gassaving-pool/contracts/GasSavingPool/impl/GSPVault.sol)
- [dodo-gassaving-pool/contracts/GasSavingPool/intf/IGSP.sol](dodo-gassaving-pool/contracts/GasSavingPool/intf/IGSP.sol)
- [dodo-gassaving-pool/contracts/lib/DODOMath.sol](dodo-gassaving-pool/contracts/lib/DODOMath.sol)
- [dodo-gassaving-pool/contracts/lib/DecimalMath.sol](dodo-gassaving-pool/contracts/lib/DecimalMath.sol)
- [dodo-gassaving-pool/contracts/lib/InitializableOwnable.sol](dodo-gassaving-pool/contracts/lib/InitializableOwnable.sol)
- [dodo-gassaving-pool/contracts/lib/PMMPricing.sol](dodo-gassaving-pool/contracts/lib/PMMPricing.sol)


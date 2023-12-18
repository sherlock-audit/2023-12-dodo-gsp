# GasSavingPool

Main Contract: ./contracts/GasSavingPool/impl/

GSP is a advanced version of DODO V2 DSP. The whole contracts of GSP uses solidity 0.8.16 version. It provides user with two methods to swap, including sellBase and sellQuote. Same as DSP, GSP supports flashloan. Compared with  of DSP and UniV3, GSP can perform swap at a cost of much lower gas fee. 

Inheritaged a template using Foundry && HardHat architecture. We use foundry test.

## Diff Report from DSP

link: [https://www.diffchecker.com/Cl4eG2Xg/](https://www.diffchecker.com/Cl4eG2Xg/)

## Test
The test of GSP implemets Foundry framework, and you can run the test using Foundry test command.

The test should be runned with forking ETH mainnet. You can set an `env.` first, then run the tests with `--fork-url $ETH_RPC_URL `.


## Motivation

With this new architecture, we can get:

- Unit tests written in solidity
- Foundry's cast
- Integration testing with Hardhat
- Hardhat deploy & verify
- Typescript

### Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum
application development written in Rust.**

Foundry consists of:

- [**Forge**](./forge): Ethereum testing framework (like Truffle, Hardhat and
  Dapptools).
- [**Cast**](./cast): Swiss army knife for interacting with EVM smart contracts,
  sending transactions and getting chain data.

**Need help getting started with Foundry? Read the [📖 Foundry
Book][foundry-book] (WIP)!**

[foundry-book]: https://onbjerg.github.io/foundry-book/

### Hardhat

Hardhat is an Ethereum development environment for professionals. It facilitates performing frequent tasks, such as running tests, automatically checking code for mistakes or interacting with a smart contract.

On [Hardhat's website](https://hardhat.org) you will find:

- [Guides to get started](https://hardhat.org/getting-started/)
- [Hardhat Network](https://hardhat.org/hardhat-network/)
- [Plugin list](https://hardhat.org/plugins/)

## Directory Structure

```
integration - "Hardhat integration tests"
lib - forge-std: "Test dependency"
scripts - "hardhat deploy scripts"
contracts - "Solidity contract"
test - "forge tests"
.env.example - "Expamle dot env"
.gitignore - "Ignore workfiles"
.gitmodules -  "Dependecy modules"
.solcover.js - "Configure coverage"
.solhint.json - "Configure solidity lint"
foundry.toml - "Configure foundry"
hardhat.config.ts - "Configure hardhat"
package.json - "Node dependencies"
README.md - "This file"
remappings.txt - "Forge dependcy mappings"
slither.config.json - "Configure slither"
```

## Installation

### Foundry

First run the command below to get `foundryup`, the Foundry toolchain installer:

```sh
curl -L https://foundry.paradigm.xyz | bash
```

If you do not want to use the redirect, feel free to manually download the
foundryup installation script from
[here](https://raw.githubusercontent.com/gakonst/foundry/master/foundryup/install).

Then, in a new terminal session or after reloading your `PATH`, run it to get
the latest `forge` and `cast` binaries:

```sh
foundryup
```

Advanced ways to use `foundryup`, and other documentation, can be found in the
[foundryup package](./foundryup/README.md). Happy forging!

### Hardhat

`npm install` or `yarn`

## Commands

```sh
Scripts available via `npm run-script`:
  compile
    npx hardhat compile
  coverage
    npx hardhat coverage --solcoverjs .solcover.js
  deploy
    npx hardhat run scripts/deploy.ts
  integration
    npx hardhat test
  verify
    npx hardhat verify
```
```sh
Hardhat Commands
  integration tests
    yarn integration
  coverage
    yarn coverage
```
```sh
Foundry Commands
  unit tests
    forge test
  coverage
    forge coverage
```
## Adding dependency

Prefer `npm` packages when available and update the remappings.

### Example

install:
`yarn add -D @openzeppelin/contracts`

remapping:
`@openzeppelin/contracts=node_modules/@openzeppelin/contracts`

import:
`import "@openzeppelin/contracts/token/ERC20/ERC20.sol";`

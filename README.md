# VaultFactory
An all new i-Fi || My-Fi || We-Fi protocol to handle payments and distribution for groups, teams, and individuals.

## Made with <3
Perfect for Web3 / DApps.

## Requirements
Solidity 0.8.13

## Problem
No known standard or protocol simply handles the payments and distribution properly for DApps.

## Solution
VaultFactory manages deployment of Vaults based around a team authentication layer, which combines the use of ERC20 & ETH, and a splitter. 

## Early-Stage Implementations (pre-release)
Deployed to:
Ropsten: https://ropsten.etherscan.io/address/0x42c21Ec24cBFF9b010F50a8D1dD44b049783EF3A

Kekchain: https://testnet-explorer.kekchain.com/address/0xfC9A4D96D405eBb81d0bd0951bA7e5c631771D10

## Current Features

This is a stable release of VaultFactory/i-Vault... aka iVF/iV.
Soon MasterOfVaults aka MoV;

Including many features such as:

**Calls from VaultFactory to iVault(x)** 
- **AUTH**: Multi-user Auth() layer (introduces an all new style of decentralized "ownable")
- **deployVaults**: Deploy iVaults (bulk)
- **fundVault/fundVaults**: Fund iVaults in ether (solo && bulk)
- **balanceOf**: Check iVault(x) balance in native ether/kek (solo)
- **balanceOfToken**: Check iVault(x) balance in token (solo)
- **balanceOfVaults**: Check iVaults balances in ether or token (bulk)
- **wrapVault**: Wrap iVaults ether balance to WETH/WKEK (solo)
- **withdrawTokenFrom**/**batchVaultRange**: Withdraw ERC20 tokens from iVaults (bulk && solo)
- **withdrawFrom**/**batchVaultRange**: Withdraw native coin (ether/KEK) from iVaults (bulk && solo)
- **withdraw**: {simultaneous} Deploy an iVault && Transfer native coin (ether/KEK) from VaultFactory to deployed iVault && Withdraw balance from deployed iVault (solo)
- **withdrawToken**: {simultaneous} Deploy an iVault && Transfer ERC20 (token) from VaultFactory to the deployed iVault && Withdraw the ERC20 from deployed iVault (solo)
- **receive**//**fallback**: {simultaneous} Send native coin (ether/KEK) to VaultFactory. On receive()... Auto-Deploy an iVault && Auto-Fund deployed iVault (solo)
- **withdrawFundsFromVaultTo**: Withdraw native coin (ether/KEK) from iVault to alt-receiver, replace pre-authorized wallet (required sender must be the wallet to replace)
- **indexOfWallet**: iVault wallet address to Vault Index
- **walletOfIndex**: iVault index to wallet address 
- **safeAddr**: Safety check to detect && enforce prevention of funding/calling to or on a dead address (i.e. wallet does not exist in VaultMap index)


**Calls to iVault(x)** 
- **setShards**: alter community funding percentage, switch token funding on/off
- **setCommunity**: change community wallet address FromWallet to toWallet (including authorization status)
- **setDevelopment**: change development wallet address FromWallet to toWallet (including authorization status)
- **vaultDebt**: returns an operator or member coinAmountOwed, tokenAmountOwed, wkekAmountOwed, coinAmountDrawn, tokenAmountDrawn, as well as the total lifetime tokenDeposited, and coinDepostied
- **deposit**: triggers splitAndStore, increments tokenDeposited and coinDeposited
- **splitAndStore**: increments member coinAmountDeposited, and community/development coinAmountOwed, tokenAmountOwed, wkekAmountOwed (detects coin/token/WETH/customToken)
- **split**: splits an amount of liquidity following preset (setShards adjustable) conditions
- **tokenizeWETH**: tokenize an iVaults native ether/kek balance to WETH/WKEK
- **withdraw**: split, and withdraw an iVault(x) balance in native ether/kek to community/development 
- **withdrawToken**: split, and withdraw an iVault(x) token balance to community/development 
- **synced**: enforce iVault token balance is synchronized as a pre-transfer out correction. (ex. someone sent token to the contract, and did not call deposit)
- **transfer**: splits and transfers out native ether/KEK to an alternate receiver address (ex. community wants to draw native coin ether/KEK from an iVault to a different address than the preset variable.


**MORE FEATURES COMING SOON!** 

**Contact**: interchained@gmail.com 
If you make use of this repository or it's contracts, kindly consider donating any coin or token to our wallets. All proceeds fund our research and development cohort, and support alt-ethereum expansion in the EVM space.


Thanks for reading. Good luck!
Have a wonderful day or night!

# Donations 

**Send Donations to:**:
```
0xb869F2E44943E66A26376bD1450ba99e26C9579E
```

# Customizations || Requests
We are Interchained

Email: interchained@gmail.com
Telegram: https://t.me/interchained

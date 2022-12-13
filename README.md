# Create a key value store using Tableland as the engine.

This is a novel ERC721 contract that wraps Tableland to provide novel functionality: a key value store.

It achieves this by allowing anyone to "mint" a new key value store. That store is a table on Tableland. The owner is allowed to update the table and grant permissions to other addresses to update. The scope of what they can do with the table (insert, update, delete key values) is defined by the smart contract. New KV are represented as novel NFTs owned by the original creator.

## Overview

## Smart contract

Contract running on Polygon Mumbai:
https://mumbai.polygonscan.com/address/0x81A0f6fDdD81f8dEed49316C3f040718aF2c9202#writeProxyContract

### How to use Wedis smart contract

#### Create a new KV

Use the `safeMint` function. `address` should be your wallet address. `name` is a custom name for your kv store.

#### Insert a new value in the KV

Use the `runSQL` method to send full SQL statements.

Or, use the `addKeyValue` method and `updateValue` methods to insert and update key values.

#### Add new writers to your KV stores

Use the `grant` method to grant write access to any KV store to a new address. You can now instantly collaborate on the same KV store.

#### Connect with the Tableland SDK and CLI

You can connect directly to this contract with the SDK and CLI by specifying the contract address. That will allow you to create new KV stores or update values from your code easily.

## Tokens generated

Contract collection on Opensea testnets:
https://testnets.opensea.io/collection/wedis-h4v5lmgwc9

## Develop

You must have a `.env` file with the following information

```
PRIVATE_KEY={your wallet key with a balance of matic}
POLYGONSCAN_API_KEY={your polyscan api key for pushing the abi}
POLYGON_MUMBAI_API_KEY={your alchemy api key for mumbai}
REPORT_GAS=true
```

### Install

`npm install`

### Start Tableland locally

`npm run tableland`

### Deploy to local hardhat

`npm run local` or upgrade `npm run localup`

### Deploy to Mumbai

`npm run deploy`

# Warning

This example is not maintained.

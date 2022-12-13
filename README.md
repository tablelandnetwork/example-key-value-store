# A Shared File System on Tableland & IPFS

A simple file manager UI running on top of a filesystem built with IPFS and Tableland.

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


## Background

The longer format write-up for how to design a data dao using Tableland and Filecoin can be found here: [How to build a DAO owned filesystem with Tableland and Filecoin](https://textile.notion.site/How-to-build-a-DAO-owned-filesystem-with-Tableland-and-Filecoin-2e7c6e5dca704761b68e19c831a5ce55).

This repo contains the examples for how to structure the tables of metadata and build interfaces to read and modify those tables. 


# Warning

This example is not maintained.
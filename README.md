# PME Land Core NFT

The **PME Land Core NFT** repository contains the core smart contract for managing land as NFTs within the **PCO Meta Earth (PME)** ecosystem. This contract enables users to convert purchased lands into NFTs, providing unique tokenized representations of their virtual properties.

---

## Contract Overview

### LandNFT
The `LandNFT` contract is an ERC721-compliant smart contract that allows for:
- **Token URI Management**: Uses storage-based URI management to define and update metadata for each NFT.
- **Pausable Transfers**: Includes functionality to pause token transfers in case of emergencies.
- **Role-Based Access Control**: Manages administrative operations such as pausing and setting token URIs through roles.
- **Enumerable Functionality**: Supports enumeration of NFTs owned by an address or existing in the collection.
- **Reentrancy Protection**: Ensures the contract is safe from reentrancy attacks during critical operations.

#### Key Features:
- Users can convert purchased lands into NFTs using the contract's functions.
- Administrators can manage metadata and contract state using role-based access controls.
- Fully upgradeable, allowing seamless integration of new features in the future.

---

## Directory Structure

```plaintext
contracts/
└── LandNFT.sol   # The core NFT contract for land management in the PME ecosystem

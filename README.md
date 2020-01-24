# merkle-tree-rollup

This library provides "pure" type roll up functions for merkle tree structure. Implementer can choose or implement own hash function to calculate the branch node.

[examples](./contracts/examples)
[test codes](./test)

## How to use

### Install

```shell
npm install merkle-tree-rollup
```

### Import and use the roll up tree you want to use

```solidity
pragma solidity >= 0.6.0;

import { Tree } from "merkle-tree-rollup/contracts/library/Types.sol";
import { MiMCTree } from "merkle-tree-rollup/contracts/trees/MiMCTree.sol";

contract MiMCExample is MiMCTree {
    Tree public tree;

    constructor() public {
        tree = newTree();
    }

    function push(
        uint[] memory leaves,
        uint[] memory initialSiblings
    ) public {
        uint newRoot = rollUp(tree.root, tree.index, leaves, initialSiblings);
        tree.root = newRoot;
        tree.index += leaves.length;
    }
}
```

### Implement your custom hash function

This is an example of roll up contract using keccak256 which depth is 7

```solidity
pragma solidity >= 0.6.0;

import { RollUpTree } from "merkle-tree-rollup/contracts/library/RollUpTree.sol";

contract KeccaTree is RollUpTree {
    function parentOf(uint left, uint right) public override pure returns (uint) {
        return uint(keccak256(abi.encodePacked(left, right)));
    }

    function preHashedZero() public override pure returns (uint[] memory preHashed) {
        preHashed = new uint[](8);
        preHashed[0] = 0x0000000000000000000000000000000000000000000000000000000000000000;
        preHashed[1] = 0xad3228b676f7d3cd4284a5443f17f1962b36e491b30a40b2405849e597ba5fb5;
        preHashed[2] = 0xb4c11951957c6f8f642c4af61cd6b24640fec6dc7fc607ee8206a99e92410d30;
        preHashed[3] = 0x21ddb9a356815c3fac1026b6dec5df3124afbadb485c9ba5a3e3398a04b7ba85;
        preHashed[4] = 0xe58769b32a1beaf1ea27375a44095a0d1fb664ce2dd358e7fcbfb78c26a19344;
        preHashed[5] = 0x0eb01ebfc9ed27500cd4dfc979272d1f0913cc9f66540d7e8005811109e1cf2d;
        preHashed[6] = 0x887c22bd8750d34016ac3c66b5ff102dacdd73f6b014e710b51e8022af9a1968;
        preHashed[7] = 0xffd70157e48063fc33c97a050f7f640233bf646cc98d9524c6b92bcf3ab56f83;
        //...
    }
}
```

### APIs

#### RollUpTree.sol

You can implement a custom hash function by inheriting `RollUpTree` contract. `RollUpTree` has the following interface.

```solidity
/**
  * @param prevRoot The previous root of the merkle tree
  * @param index The index where new leaves start
  * @param leaves Items to append to the merkle tree
  * @param initialSiblings Sibling data for the merkle proof of the prevRoot
  * @return new root after appending the given leaves
  */
function rollUp(
    uint prevRoot,
    uint index,
    uint[] memory leaves,
    uint[] memory initialSiblings
) public pure returns (uint);

/**
 * @param root The roof of a merkle tree
 * @param leaf The leaf to prove the membership
 * @param index Where the leaf is located in
 * @param siblings The sibling data of the given leaf
 * @return proof result in boolean
 */
function merkleProof(
    uint root,
    uint leaf,
    uint index,
    uint[] memory siblings
) public pure returns (bool);

/**
 * @dev You should implement how to calculate the branch node. The implementation
 *      can be differ by which hash function you use.
 */
function parentOf(uint left, uint right) public virtual pure returns (uint);

/**
 * @dev Merkle tree for roll up consists of empty leaves at first. Therefore you
 *      can reduce the hash cost by using hard-coded pre hashed zero value arrays.
 *      If you want to use a merkle tree which depth is 4, you should return a hard coded
 *      array of uint which length is 5. And the value should be equivalent to the following
 *      [0, hash(0, 0), hash(hash(0,0, hash(0,0)))...]
 */
function preHashedZero() public virtual pure returns (uint[] memory preHashed);
```

#### RollUpLib.sol

Or you can implement your own tree contract using the roll up library. `RollUpLib` provides the following functions.

```solidity
function rollUp(
    Hasher memory self,
    uint startingRoot,
    uint index,
    uint[] memory leaves,
    uint[] memory initialSiblings
) internal pure returns (uint newRoot);

function merkleRoot(
    Hasher memory self,
    uint leaf,
    uint index,
    uint[] memory siblings
) internal pure returns (uint);

function merkleProof(
    Hasher memory self,
    uint root,
    uint leaf,
    uint index,
    uint[] memory siblings
) internal pure returns (bool);

/**
 * @dev It returns an initialized merkle tree which leaves are all empty.
 */
function newTree(Hasher memory hasher) internal pure returns (Tree memory tree) {
    tree.root = hasher.preHashedZero[hasher.preHashedZero.length - 1];
    tree.index = 0;
}
```

#### StorageRollupTree.sol

Even the custom hash function is too expensive, you can roll up many leaves using storage. It stores the intermediate siblings instead of validating the merkle proof everytime. Especially if the hash function is more expensive than 5000 gas using this implementation will help the scalability.

```solidity
/**
 * @dev Create a new roll up object and store it. It requires the valid
 *      sibling data to start the roll up. The starting leaf and every leaf
 *      behind that should be the empty leaves.
 */
function newRollUp(
    uint startingRoot,
    uint startingIndex,
    uint[] memory initialSiblings
) public virtual returns (uint id);

/**
 * @dev Update the storage roll up by appending given leaves.
 *      Only the creator is allowed to append new leaves.
 */
function append(
    uint rollUpId,
    uint[] memory leaves
) public virtual;

/**
 * @return It returns the validity of the storage roll up
 */
function verifyRollUp(
    uint rollUpId,
    uint startingRoot,
    uint startingIndex,
    uint targetingRoot,
    uint[] memory leaves
) public view returns (bool)
```

#### StorageRollUpLib.sol

You can use the above StorageRollUpBase or you can implement your own storage roll up contract using the library `StorageRollUpLib`. This library provides the following functions.

```solidity
/**
 * @dev When the hash function is very expensive, a roll up can be accomplished through
 * multiple transactions. If the hash function is more expensive than 5,000 gas it is
 * effective to use storage than veritying the initial siblings everytime.
 */
function initStorageRollUp(
    Hasher memory self,
    StorageRollUp storage sRollUp,
    uint startingRoot,
    uint index,
    uint[] memory initialSiblings
) internal;

/**
 * @dev Append given leaves to the storage roll up and store it.
 */
function appendToStorageRollUp(
    Hasher memory self,
    StorageRollUp storage sRollUp,
    uint[] memory leaves
) internal;

/**
 * @dev Check the given parameters roll up assertion is true based on
 *      its storage roll up result
 */
function verify(
    StorageRollUp memory self,
    uint startingRoot,
    uint startingIndex,
    uint targetingRoot,
    bytes32 mergedLeaves
) internal pure returns (bool);

/**
 * @dev Appended leaves will be merged into a single bytes32 value sequentially
 *      and that will be used to validate the correct sequence of the total
 *      appended leaves through multiple transactions.
 */
function mergeLeaves(bytes32 base, uint[] memory leaves) internal pure returns (bytes32)
```

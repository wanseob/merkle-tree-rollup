# merkle-tree-rollup

This library provides "pure" type roll up functions for merkle tree structure. Implementer can choose or implement own hash function to calculate the branch node.

## How to use

#### Install

```shell
npm install merkle-tree-rollup
```

#### APIs

```solidity
function rollUp(
    uint prevRoot,
    uint index,
    uint[] memory leaves,
    uint[] memory initialSiblings
) public pure returns (uint);

function merkleProof(
    uint root,
    uint leaf,
    uint index,
    uint[] memory siblings
) public pure returns (bool);
```

#### Implement roll up library

This is an example of roll up contract using keccak256 which depth is 7

```solidity
pragma solidity >= 0.6.0;

import { RollUpBase } from "../RollUpBase.sol";

contract KeccakRollUp is RollUpBase {
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
    }
}
```

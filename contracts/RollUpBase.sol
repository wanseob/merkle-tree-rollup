pragma solidity >= 0.6.0;

import { Hasher, RollUpLib } from "./RollUpLib.sol";

abstract contract RollUpBase {
    using RollUpLib for Hasher;

    function rollUp(
        uint prevRoot,
        uint index,
        uint[] memory leaves,
        uint[] memory initialSiblings
    ) public pure returns (uint) {
        return hasher().rollUp(prevRoot, index, leaves, initialSiblings);
    }

    function merkleProof(
        uint root,
        uint leaf,
        uint index,
        uint[] memory siblings
    ) public pure returns (bool) {
        return hasher().merkleProof(root, leaf, index, siblings);
    }

    function hasher() internal pure returns (Hasher memory) {
        return Hasher(parentOf, preHashedZero());
    }

    function parentOf(uint left, uint right) public virtual pure returns (uint);

    function preHashedZero() public virtual pure returns (uint[] memory preHashed);
}

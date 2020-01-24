pragma solidity >= 0.6.0;

import { Hasher, Tree } from "./Types.sol";

/**
 * @author Wilson Beam <wilsonbeam@protonmail.com>
 * @title Append-only usage merkle tree roll up library
 */
library RollUpLib {
    function rollUp(
        Hasher memory self,
        uint startingRoot,
        uint index,
        uint[] memory leaves,
        uint[] memory initialSiblings
    ) internal pure returns (uint newRoot) {
        require(_startingLeafProof(self, startingRoot, index, initialSiblings), "Invalid merkle proof of starting leaf node");
        uint nextIndex = index;
        uint[] memory nextSiblings = initialSiblings;
        for(uint i = 0; i < leaves.length; i++) {
            (newRoot, nextIndex, nextSiblings) = _append(self, nextIndex, leaves[i], nextSiblings);
        }
    }

    function merkleRoot(
        Hasher memory self,
        uint leaf,
        uint index,
        uint[] memory siblings
    ) internal pure returns (uint) {
        uint path = index;
        uint node = leaf;
        for(uint i = 0; i < siblings.length; i++) {
            if(path & 1 == 0) {
                // right sibling
                node = self.parentOf(node, siblings[i]);
            } else {
                // left sibling
                node = self.parentOf(siblings[i], node);
            }
            path >>= 1;
        }
        return node;
    }

    function merkleProof(
        Hasher memory self,
        uint root,
        uint leaf,
        uint index,
        uint[] memory siblings
    ) internal pure returns (bool) {
        return merkleRoot(self, leaf, index, siblings) == root;
    }

    /**
     * @dev It returns an initialized merkle tree which leaves are all empty.
     */
    function newTree(Hasher memory hasher) internal pure returns (Tree memory tree) {
        tree.root = hasher.preHashedZero[hasher.preHashedZero.length - 1];
        tree.index = 0;
    }

    function _startingLeafProof(
        Hasher memory self,
        uint root,
        uint index,
        uint[] memory siblings
    ) internal pure returns (bool) {
        uint path = index;
        for(uint i = 0; i < siblings.length; i++) {
            if(path & 1 == 0) {
                // Right sibling should be a prehashed zero
                if(siblings[i] != self.preHashedZero[i]) return false;
            } else {
                // Left sibling should not be a prehashed zero
                if(siblings[i] == self.preHashedZero[i]) return false;
            }
            path >>= 1;
        }
        return merkleProof(self, root, self.preHashedZero[0], index, siblings);
    }

    function _append(
        Hasher memory self,
        uint index,
        uint leaf,
        uint[] memory siblings
    ) internal pure returns(
        uint nextRoot,
        uint nextIndex,
        uint[] memory nextSiblings
    ) {
        nextSiblings = new uint[](siblings.length);
        uint path = index;
        uint node = leaf;
        for(uint i = 0; i < siblings.length; i++) {
            if(path & 1 == 0) {
                // right empty sibling
                nextSiblings[i] = node; // current node will be the next merkle proof's left sibling
                node = self.parentOf(node, self.preHashedZero[i]);
            } else {
                // left sibling
                nextSiblings[i] = siblings[i]; // keep current sibling
                node = self.parentOf(siblings[i], node);
            }
            path >>= 1;
        }
        nextRoot = node;
        nextIndex = index + 1;
    }
}

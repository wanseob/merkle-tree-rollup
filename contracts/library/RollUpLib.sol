pragma solidity >= 0.6.0;

import { Hasher, Tree, OPRU, SplitRollUp } from "./Types.sol";

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

    function merkleProof(
        Hasher memory self,
        uint root,
        uint leaf,
        uint index,
        uint[] memory siblings
    ) internal pure returns (bool) {
        return merkleRoot(self, leaf, index, siblings) == root;
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

    /**
     * @dev It returns an initialized merkle tree which leaves are all empty.
     */
    function newTree(Hasher memory hasher) internal pure returns (Tree memory tree) {
        tree.root = hasher.preHashedZero[hasher.preHashedZero.length - 1];
        tree.index = 0;
    }

    function newOPRU(
        uint startingRoot,
        uint startingIndex,
        uint resultRoot,
        uint resultIndex,
        uint[] memory leaves
    ) internal pure returns (OPRU memory opru) {
        opru.start.root = startingRoot;
        opru.start.index = startingIndex;
        opru.result.root = resultRoot;
        opru.result.index = resultIndex;
        opru.mergedLeaves = merge(bytes32(0), leaves);
    }

    function newSplitRollUp(
        uint startingRoot,
        uint index
    ) internal pure returns (SplitRollUp memory splitRollUp) {
        splitRollUp.start.root = startingRoot;
        splitRollUp.result.root = startingRoot;
        splitRollUp.start.index = index;
        splitRollUp.result.index = index;
        splitRollUp.mergedLeaves = bytes32(0);
        return splitRollUp;
    }

    /**
     * @dev If you start the split roll up using this function, you don't need to submit and verify
     *      the every time. Approximately, if the hash function is more expensive than 5,000 gas,
     *      it becomes to cheaper to record the intermediate siblings on-chain.
     *      To be specific, record intermediate siblings when v > 5000 + 20000/(n-1)
     *      v: gas cost of the hash function, n: how many times to call 'update'
     */
    function initAndSaveSiblings(
        Hasher memory self,
        SplitRollUp storage splitRollUp,
        uint startingRoot,
        uint index,
        uint[] memory initialSiblings
    ) internal {
        require(_startingLeafProof(self, startingRoot, index, initialSiblings), "Invalid merkle proof of the starting leaf node");
        splitRollUp.start.root = startingRoot;
        splitRollUp.result.root = startingRoot;
        splitRollUp.start.index = index;
        splitRollUp.result.index = index;
        splitRollUp.mergedLeaves = bytes32(0);
        splitRollUp.siblings = initialSiblings;
    }

    /**
     * @dev Append given leaves to the SplitRollUp with verifying the siblings.
     * @param splitRollUp The SplitRollUp to update
     * @param initialSiblings Initial siblings to start roll up.
     * @param leaves Items to append to the tree.
     */
    function update(
        Hasher memory self,
        SplitRollUp storage splitRollUp,
        uint[] memory initialSiblings,
        uint[] memory leaves
    ) internal {
        splitRollUp.result.root = rollUp(self, splitRollUp.result.root, splitRollUp.result.index, initialSiblings, leaves);
        splitRollUp.result.index += leaves.length;
        splitRollUp.mergedLeaves = merge(splitRollUp.mergedLeaves, leaves);
    }

    /**
     * @dev Append the given leaves using the on-chain sibling data.
     *      You can use this function when only you started the SplitRollUp using
     *      initAndSaveSiblings()
     * @param splitRollUp The SplitRollUp to update
     * @param leaves Items to append to the tree.
     */
    function update(
        Hasher memory self,
        SplitRollUp storage splitRollUp,
        uint[] memory leaves
    ) internal {
        require(
            splitRollUp.siblings.length != 0,
            "The on-chain siblings are not initialized"
        );
        uint nextIndex = splitRollUp.result.index;
        uint[] memory nextSiblings = splitRollUp.siblings;
        uint newRoot;
        for(uint i = 0; i < leaves.length; i++) {
            (newRoot, nextIndex, nextSiblings) = _append(self, nextIndex, leaves[i], nextSiblings);
        }
        bytes32 mergedLeaves = merge(splitRollUp.mergedLeaves, leaves);
        splitRollUp.result.root = newRoot;
        splitRollUp.result.index = nextIndex;
        splitRollUp.mergedLeaves = mergedLeaves;
        for(uint i = 0; i < nextSiblings.length; i++) {
            splitRollUp.siblings[i] = nextSiblings[i];
        }
    }

    /**
     * @dev Check that the given optimistic roll up is valid using the
     *      on-chain calculated roll up.
     */
    function verify(
        SplitRollUp memory self,
        OPRU memory opru
    ) internal pure returns (bool) {
        require(self.start.root == opru.start.root, "Starting root is different");
        require(self.start.index == opru.start.index, "Starting index is different");
        require(self.mergedLeaves == opru.mergedLeaves, "Appended leaves are different");
        require(self.result.index == opru.result.index, "Result index is different");
        return self.result.root == opru.result.root;
    }

    /**
     * @dev Appended leaves will be merged into a single bytes32 value sequentially
     *      and that will be used to validate the correct sequence of the total
     *      appended leaves through multiple transactions.
     */
    function merge(bytes32 base, uint[] memory leaves) internal pure returns (bytes32) {
        bytes32 merged = base;
        for(uint i = 0; i < leaves.length; i ++) {
            merged = keccak256(abi.encodePacked(merged, leaves[i]));
        }
        return merged;
    }

    function merge(bytes32 base, bytes32[] memory leaves) internal pure returns (bytes32) {
        bytes32 merged = base;
        for(uint i = 0; i < leaves.length; i ++) {
            merged = keccak256(abi.encodePacked(merged, leaves[i]));
        }
        return merged;
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

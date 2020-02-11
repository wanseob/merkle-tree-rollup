pragma solidity >= 0.6.0;

import { RollUpLib } from "./RollUpLib.sol";
import { Hasher, Tree, SplitRollUp } from "./Types.sol";

/**
 * @author Wilson Beam <wilsonbeam@protonmail.com>
 * @title Append-only usage merkle tree roll up library
 */
library SubTreeRollUpLib {
    using RollUpLib for Hasher;
    using RollUpLib for bytes32;

    function rollUpSubTree(
        Hasher memory self,
        uint startingRoot,
        uint index,
        uint subTreeDepth,
        uint[] memory leaves,
        uint[] memory subTreeSiblings
    ) internal pure returns (uint newRoot) {
        require(index % (1 << subTreeDepth) == 0, "Can't merge the subTree");
        require(_emptySubTreeProof(self, startingRoot, index, subTreeDepth, subTreeSiblings), "Invalid merkle proof of starting leaf node");
        uint nextIndex = index;
        uint[][] memory subTrees = splitToSubTrees(leaves, subTreeDepth);
        uint[] memory nextSiblings = subTreeSiblings;
        for(uint i = 0; i < subTrees.length; i++) {
            (newRoot, nextIndex, nextSiblings) = _appendSubTree(
                self,
                nextIndex,
                subTreeDepth,
                subTrees[i],
                nextSiblings
            );
        }
    }

    /**
     * @dev If you start the split roll up using this function, you don't need to submit and verify
     *      the every time. Approximately, if the hash function is more expensive than 5,000 gas,
     *      it becomes to cheaper to record the intermediate siblings on-chain.
     *      To be specific, record intermediate siblings when v > 5000 + 20000/(n-1)
     *      v: gas cost of the hash function, n: how many times to call 'update'
     */
    function initSubTreeRollUp(
        Hasher memory self,
        SplitRollUp storage splitRollUp,
        uint startingRoot,
        uint index,
        uint subTreeDepth,
        uint[] memory subTreeSiblings
    ) internal {
        require(_emptySubTreeProof(self, startingRoot, index, subTreeDepth, subTreeSiblings), "Invalid merkle proof of starting leaf node");
        splitRollUp.start.root = startingRoot;
        splitRollUp.result.root = startingRoot;
        splitRollUp.start.index = index;
        splitRollUp.result.index = index;
        splitRollUp.mergedLeaves = bytes32(0);
        splitRollUp.siblings = subTreeSiblings;
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
        uint subTreeDepth,
        uint[] memory leaves
    ) internal {
        uint nextIndex = splitRollUp.result.index;
        uint[] memory nextSiblings = splitRollUp.siblings;
        uint newRoot;
        (newRoot, nextIndex, nextSiblings) = _appendSubTree(
            self,
            nextIndex,
            subTreeDepth,
            leaves,
            nextSiblings
        );
        bytes32 mergedLeaves = splitRollUp.mergedLeaves.merge(leaves);
        splitRollUp.result.root = newRoot;
        splitRollUp.result.index = nextIndex;
        splitRollUp.mergedLeaves = mergedLeaves;
        for(uint i = 0; i < nextSiblings.length; i++) {
            splitRollUp.siblings[i] = nextSiblings[i];
        }
    }

    function splitToSubTrees(
        uint[] memory leaves,
        uint subTreeDepth
    ) internal pure returns (uint[][] memory subTrees) {
        uint subTreeSize = 1 << subTreeDepth;
        uint numOfSubTrees = (leaves.length / subTreeSize) + (leaves.length % subTreeSize == 0 ? 0 : 1);
        subTrees = new uint[][](numOfSubTrees);
        for (uint i = 0; i < numOfSubTrees; i++) {
            subTrees[i] = new uint[](subTreeSize);
        }
        uint index = 0;
        uint subTreeIndex = 0;
        for(uint i = 0; i < leaves.length; i++) {
            subTrees[subTreeIndex][index] = leaves[i];
            if(index < subTreeSize - 1) {
                index += 1;
            } else {
                index = 0;
                subTreeIndex += 1;
            }
        }
    }

    /**
     * @param siblings If the merkle tree depth is "D" and the subTree's
     *          depth is "d", the length of the siblings should be "D - d".
     */
    function _emptySubTreeProof(
        Hasher memory self,
        uint root,
        uint index,
        uint subTreeDepth,
        uint[] memory siblings
    ) internal pure returns (bool) {
        uint subTreePath = index >> subTreeDepth;
        uint path = subTreePath;
        for(uint i = 0; i < siblings.length; i++) {
            if(path & 1 == 0) {
                // Right sibling should be a prehashed zero
                if(siblings[i] != self.preHashedZero[i + subTreeDepth]) return false;
            } else {
                // Left sibling should not be a prehashed zero
                if(siblings[i] == self.preHashedZero[i + subTreeDepth]) return false;
            }
            path >>= 1;
        }
        return self.merkleProof(root, self.preHashedZero[subTreeDepth], subTreePath, siblings);
    }

    function _appendSubTree(
        Hasher memory self,
        uint index,
        uint subTreeDepth,
        uint[] memory subTreeLeaves,
        uint[] memory siblings
    ) internal pure returns(
        uint nextRoot,
        uint nextIndex,
        uint[] memory nextSiblings
    ) {
        nextSiblings = new uint[](siblings.length);
        uint subTreePath = index >> subTreeDepth;
        uint path = subTreePath;
        uint node = _subTreeRoot(self, subTreeDepth, subTreeLeaves);
        for (uint i = 0; i < siblings.length; i++) {
            if (path & 1 == 0) {
                // right empty sibling
                nextSiblings[i] = node; // current node will be the next merkle proof's left sibling
                node = self.parentOf(node, self.preHashedZero[i + subTreeDepth]);
            } else {
                // left sibling
                nextSiblings[i] = siblings[i]; // keep current sibling
                node = self.parentOf(siblings[i], node);
            }
            path >>= 1;
        }
        nextRoot = node;
        nextIndex = index + (1 << subTreeDepth);
    }

    function _subTreeRoot(
        Hasher memory self,
        uint subTreeDepth,
        uint[] memory leaves
    ) internal pure returns (uint) {
        /// Example of a sub tree with depth 3
        ///                      1
        ///          10                       11
        ///    100        101         110           [111]
        /// 1000 1001  1010 1011   1100 [1101]  [1110] [1111]
        ///   o   o     o    o       o    x       x       x
        ///
        /// whereEmptyNodeStart (1101) = leaves.length + tree_size
        /// []: nodes that we can use the pre hashed zeroes
        ///
        /// * ([1101] << 0) is gte than (1101) => we can use the pre hashed zeroes
        /// * ([1110] << 0) is gte than (1101) => we can use the pre hashed zeroes
        /// * ([1111] << 0) is gte than (1101) => we can use pre hashed zeroes
        /// * ([111] << 1) is gte than (1101) => we can use pre hashed zeroes
        /// * (11 << 2) is less than (1101) => we cannot use pre hashed zeroes
        /// * (1 << 3) is less than (1101) => we cannot use pre hashed zeroes

        uint treeSize = 1 << subTreeDepth;
        require(leaves.length <= treeSize, "Overflowed");

        uint[] memory nodes = new uint[](treeSize << 1); /// we'll not use nodes[0]
        uint emptyNode = treeSize + (leaves.length - 1); /// we do not hash if we can use pre hashed zeroes
        uint leftMostOfTheFloor = treeSize;

        /// From the bottom to the top
        for(uint level = 0; level <= subTreeDepth; level++) {
            /// From the right to the left
            for(
                uint nodeIndex = (treeSize << 1) - 1;
                nodeIndex >= leftMostOfTheFloor;
                nodeIndex--
            )
            {
                if (nodeIndex <= emptyNode) {
                    /// This node is not an empty node
                    if (level == 0) {
                        /// Leaf node
                        nodes[nodeIndex] = leaves[nodeIndex - treeSize];
                    } else {
                        /// Parent node
                        uint leftChild = nodeIndex << 1;
                        uint rightChild = leftChild + 1;
                        nodes[nodeIndex] = self.parentOf(nodes[leftChild], nodes[rightChild]);
                    }
                } else {
                    /// Use pre hashed
                    nodes[nodeIndex] = self.preHashedZero[level];
                }
            }
            leftMostOfTheFloor >>= 1;
            emptyNode >>= 1;
        }
    }
}

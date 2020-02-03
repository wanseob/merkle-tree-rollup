pragma solidity >= 0.6.0;

import { Hasher, OPRU, ExtendedOPRU } from "./Types.sol";
import { RollUpLib } from "./RollUpLib.sol";

library OPRULib {
    using RollUpLib for Hasher;

    function newOPRU(
        uint startingRoot,
        uint index
    ) internal pure returns (OPRU memory opru) {
        opru.start.root = startingRoot;
        opru.result.root = startingRoot;
        opru.start.index = index;
        opru.result.index = index;
        opru.mergedLeaves = bytes32(0);
        return opru;
    }
    
    /**
     * @dev If the hash function is more expensive than 5,000 gas it is effective
     *      to use storage than veritying the initial siblings everytime.
     */
    function initExtendedOPRU(
        Hasher memory self,
        ExtendedOPRU storage extended,
        uint startingRoot,
        uint index,
        uint[] memory initialSiblings
    ) internal {
        require(self._startingLeafProof(startingRoot, index, initialSiblings), "Invalid merkle proof of the starting leaf node");
        extended.opru = newOPRU(startingRoot, index);
        extended.siblings = initialSiblings;
    }

    /**
     * @dev Append given leaves to the opru and store it.
     */
    function update(
        Hasher memory self,
        OPRU storage opru,
        uint[] memory initialSiblings,
        uint[] memory leaves
    ) internal {
        opru.result.root = self.rollUp(opru.result.root, opru.result.index, initialSiblings, leaves);
        opru.result.index += leaves.length;
        opru.mergedLeaves = mergeLeaves(opru.mergedLeaves, leaves);
    }

    /**
     * @dev Append given leaves to the extended opru and store it.
     */
    function update(
        Hasher memory self,
        ExtendedOPRU storage extended,
        uint[] memory leaves
    ) internal {
        uint nextIndex = extended.opru.result.index;
        uint[] memory nextSiblings = extended.siblings;
        uint newRoot;
        for(uint i = 0; i < leaves.length; i++) {
            (newRoot, nextIndex, nextSiblings) = self._append(nextIndex, leaves[i], nextSiblings);
        }
        bytes32 mergedLeaves = mergeLeaves(extended.opru.mergedLeaves, leaves);
        extended.opru.result.root = newRoot;
        extended.opru.result.index = nextIndex;
        extended.opru.mergedLeaves = mergedLeaves;
        for(uint i = 0; i < nextSiblings.length; i++) {
            extended.siblings[i] = nextSiblings[i];
        }
    }

    /**
     * @dev Check the given parameters roll up assertion is true based on
     *      its storage roll up result
     */
    function verify(
        OPRU memory self,
        uint startingRoot,
        uint startingIndex,
        uint targetingRoot,
        bytes32 mergedLeaves
    ) internal pure returns (bool) {
        require(self.start.root == startingRoot, "Starting root is different");
        require(self.start.index == startingIndex, "Starting index is different");
        require(self.mergedLeaves == mergedLeaves, "Appended leaves are different");
        return self.result.root == targetingRoot;
    }

    /**
     * @dev Appended leaves will be merged into a single bytes32 value sequentially
     *      and that will be used to validate the correct sequence of the total
     *      appended leaves through multiple transactions.
     */
    function mergeLeaves(bytes32 base, uint[] memory leaves) internal pure returns (bytes32) {
        bytes32 merged = base;
        for(uint i = 0; i < leaves.length; i ++) {
            merged = keccak256(abi.encodePacked(merged, leaves[i]));
        }
        return merged;
    }

    function mergeLeaves(bytes32 base, bytes32[] memory leaves) internal pure returns (bytes32) {
        bytes32 merged = base;
        for(uint i = 0; i < leaves.length; i ++) {
            merged = keccak256(abi.encodePacked(merged, leaves[i]));
        }
        return merged;
    }
}

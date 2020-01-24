pragma solidity >= 0.6.0;

import { Hasher, StorageRollUp } from "./Types.sol";
import { RollUpLib } from "./RollUpLib.sol";

library StorageRollUpLib {
    using RollUpLib for Hasher;

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
    ) internal {
        require(!sRollUp.initialized, "Already initialized");
        require(self._startingLeafProof(startingRoot, index, initialSiblings), "Invalid merkle proof of the starting leaf node");
        sRollUp.start.root = startingRoot;
        sRollUp.result.root = startingRoot;
        sRollUp.start.index = index;
        sRollUp.result.index = index;
        sRollUp.mergedLeaves = bytes32(0);
        for(uint i = 0; i < initialSiblings.length; i++) {
            sRollUp.siblings.push(initialSiblings[i]);
        }
        sRollUp.initialized = true;
    }

    /**
     * @dev Append given leaves to the storage roll up and store it.
     */
    function appendToStorageRollUp(
        Hasher memory self,
        StorageRollUp storage sRollUp,
        uint[] memory leaves
    ) internal {
        require(sRollUp.initialized, "Not initialized");
        uint nextIndex = sRollUp.result.index;
        uint[] memory nextSiblings = sRollUp.siblings;
        uint newRoot;
        for(uint i = 0; i < leaves.length; i++) {
            (newRoot, nextIndex, nextSiblings) = self._append(nextIndex, leaves[i], nextSiblings);
        }
        bytes32 mergedLeaves = mergeLeaves(sRollUp.mergedLeaves, leaves);
        for(uint i = 0; i < nextSiblings.length; i++) {
            sRollUp.siblings[i] = nextSiblings[i];
        }
        sRollUp.mergedLeaves = mergedLeaves;
        sRollUp.result.root = newRoot;
        sRollUp.result.index = nextIndex;
    }

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
    ) internal pure returns (bool) {
        require(self.initialized, "Not an initialized storage roll up");
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
}

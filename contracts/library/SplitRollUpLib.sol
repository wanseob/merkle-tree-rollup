pragma solidity >= 0.6.0;

import { Hasher, OPRU, SplitRollUp } from "./Types.sol";
import { RollUpLib } from "./RollUpLib.sol";

library SplitRollUpLib {
    using RollUpLib for Hasher;
    using RollUpLib for bytes32;

    function newSplitRollUp(
        uint startingRoot,
        uint index
    ) internal pure returns (SplitRollUp memory rollUp) {
        rollUp.start.root = startingRoot;
        rollUp.result.root = startingRoot;
        rollUp.start.index = index;
        rollUp.result.index = index;
        rollUp.mergedLeaves = bytes32(0);
        return rollUp;
    }

    /**
     * @dev If the hash function is more expensive than 5,000 gas it is effective
     *      to use storage than veritying the initial siblings everytime.
     */
    function initAndSaveSiblings(
        Hasher memory self,
        SplitRollUp storage rollUp,
        uint startingRoot,
        uint index,
        uint[] memory initialSiblings
    ) internal {
        require(self._startingLeafProof(startingRoot, index, initialSiblings), "Invalid merkle proof of the starting leaf node");
        rollUp.start.root = startingRoot;
        rollUp.result.root = startingRoot;
        rollUp.start.index = index;
        rollUp.result.index = index;
        rollUp.mergedLeaves = bytes32(0);
        rollUp.siblings = initialSiblings;
    }
    /**
     * @dev Append given leaves to the SplitRollUp and store it.
     */
    function update(
        Hasher memory self,
        SplitRollUp storage rollUp,
        uint[] memory initialSiblings,
        uint[] memory leaves
    ) internal {
        rollUp.result.root = self.rollUp(rollUp.result.root, rollUp.result.index, initialSiblings, leaves);
        rollUp.result.index += leaves.length;
        rollUp.mergedLeaves = rollUp.mergedLeaves.merge(leaves);
    }

    /**
     * @dev This uses the on-chain siblings.
     */
    function update(
        Hasher memory self,
        SplitRollUp storage rollUp,
        uint[] memory leaves
    ) internal {
        require(
            rollUp.siblings.length != 0,
            "The on-chain siblings are not initialized"
        );
        uint nextIndex = rollUp.result.index;
        uint[] memory nextSiblings = rollUp.siblings;
        uint newRoot;
        for(uint i = 0; i < leaves.length; i++) {
            (newRoot, nextIndex, nextSiblings) = self._append(nextIndex, leaves[i], nextSiblings);
        }
        bytes32 mergedLeaves = rollUp.mergedLeaves.merge(leaves);
        rollUp.result.root = newRoot;
        rollUp.result.index = nextIndex;
        rollUp.mergedLeaves = mergedLeaves;
        for(uint i = 0; i < nextSiblings.length; i++) {
            rollUp.siblings[i] = nextSiblings[i];
        }
    }

    /**
     * @dev Check the given parameters roll up assertion is true based on
     *      its storage roll up result
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
}

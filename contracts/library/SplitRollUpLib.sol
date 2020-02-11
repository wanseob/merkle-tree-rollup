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
     * @dev If you start the split roll up using this function, you don't need to submit and verify
     *      the every time. Approximately, if the hash function is more expensive than 5,000 gas,
     *      it becomes to cheaper to record the intermediate siblings on-chain.
     *      To be specific, record intermediate siblings when v > 5000 + 20000/(n-1)
     *      v: gas cost of the hash function, n: how many times to call 'update'
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
     * @dev Append given leaves to the SplitRollUp with verifying the siblings.
     * @param rollUp The SplitRollUp to update
     * @param initialSiblings Initial siblings to start roll up.
     * @param leaves Items to append to the tree.
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
     * @dev Append the given leaves using the on-chain sibling data.
     *      You can use this function when only you started the SplitRollUp using
     *      initAndSaveSiblings()
     * @param rollUp The SplitRollUp to update
     * @param leaves Items to append to the tree.
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
}

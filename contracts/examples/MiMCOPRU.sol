pragma solidity >= 0.6.0;

import { Tree } from "../library/Types.sol";
import { MiMCTree } from "../trees/MiMCTree.sol";
import { StorageRollUpLib } from "../library/StorageRollUpLib.sol";
import { StorageRollUpBase } from "../library/StorageRollUpBase.sol";

contract MiMCOPRU is StorageRollUpBase, MiMCTree {
    Tree tree;

    struct Submission {
        Tree prevTree;
        Tree newTree;
        address submitter;
        uint challengeDue;
        bool slashed;
    }

    mapping(bytes32=>Submission) submissions;
    mapping(address=>bool) slashed;

    uint constant public challengePeriod = 0;
    constructor() public {
    }

    function submitOPRU(
        uint startingRoot,
        uint startingIndex,
        uint[] memory leaves,
        uint targetingRoot
    ) public {
        require(!slashed[msg.sender], "Not allowed to submit");
        bytes32 opruId = keccak256(abi.encodePacked(startingRoot, startingIndex, leaves, targetingRoot));
        submissions[opruId] = Submission(
            Tree(startingRoot, startingIndex),
            Tree(targetingRoot, startingIndex + leaves.length),
            msg.sender,
            now + challengePeriod,
            false
        );
    }

    function finalizeOPRU(bytes32 opruId) public {
        Submission storage submission = submissions[opruId];
        require(!submission.slashed, "Submission is slashed");
        require(submission.challengeDue <= now, "Can't finalized");
        require(
            submission.prevTree.root == tree.root && submission.prevTree.index == tree.index,
            "Current tree is different with the submission's prev tree"
        );
        tree = submission.newTree;
    }

    function challengeOPRU(
        uint storageRollUpId,
        uint startingRoot,
        uint startingIndex,
        uint[] memory leaves,
        uint targetingRoot
    ) public {
        bytes32 opruId = keccak256(abi.encodePacked(startingRoot, startingIndex, leaves, targetingRoot));
        Submission storage submission = submissions[opruId];
        require(!submission.slashed, "Already slashed");
        require(submission.challengeDue > now, "Not in the challenge period");
        bool verification = verifyRollUp(storageRollUpId, startingRoot, startingIndex, leaves, targetingRoot);
        if(!verification) {
            submission.slashed = true;
            slash(submission.submitter);
        }
    }

    function slash(address submitter) private {
        // Do slash here
    }
}

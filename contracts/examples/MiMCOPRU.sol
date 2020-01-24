pragma solidity >= 0.6.0;
import { Tree } from "../library/Types.sol";
import { MiMCTree } from "../trees/MiMCTree.sol";
import { StorageRollUpLib } from "../library/StorageRollUpLib.sol";
import { StorageRollUpBase } from "../library/StorageRollUpBase.sol";

contract MiMCOPRU is StorageRollUpBase, MiMCTree {
    Tree tree;

    struct Submission {
        uint startingRoot;
        uint startingIndex;
        uint targetingRoot;
        uint targetingIndex;
        bytes32 mergedLeaves;
        address submitter;
        uint challengeDue;
        bool slashed;
    }

    event NewSubmission(uint id);
    event Slashed(uint opruId, address submitter, address challenger);

    uint index = 0;
    mapping(uint=>Submission) public submissions;
    mapping(address=>bool) public slashedSubmissionters;

    uint constant public challengePeriod = 15;
    constructor() public {
        tree = newTree();
    }

    function timestamp() public view returns (uint) {
        return now;
    }

    function submitOPRU(
        uint startingRoot,
        uint startingIndex,
        uint[] memory leaves,
        uint targetingRoot
    ) public returns (uint opruId) {
        opruId = index++;
        require(!slashedSubmissionters[msg.sender], "Not allowed to submit");
        submissions[opruId] = Submission(
            startingRoot,
            startingIndex,
            targetingRoot,
            startingIndex + leaves.length,
            StorageRollUpLib.mergeLeaves(bytes32(0), leaves),
            msg.sender,
            now + challengePeriod,
            false
        );
        emit NewSubmission(opruId);
    }

    function finalizeOPRU(uint id) public {
        Submission storage submission = submissions[id];
        require(!submission.slashed, "Submission is slashed");
        require(submission.challengeDue <= now, "Still in the challenge period");
        require(
            submission.startingRoot == tree.root && submission.startingIndex == tree.index,
            "Current tree is different with the submission's prev tree"
        );
        tree.root = submission.targetingRoot;
        tree.index = submission.targetingIndex;
    }

    function challengeOPRU(uint submissionId, uint rollUpId) public {
        Submission storage submission = submissions[submissionId];
        require(!submission.slashed, "Already slashed");
        require(submission.challengeDue > now, "Not in the challenge period");
        bool verification = verifyRollUp(
            rollUpId,
            submission.startingRoot,
            submission.startingIndex,
            submission.targetingRoot,
            submission.mergedLeaves
        );
        if(!verification) {
            // Implement slash logic here
            submission.slashed = true;
            emit Slashed(submissionId, submission.submitter, msg.sender);
        }
    }
}

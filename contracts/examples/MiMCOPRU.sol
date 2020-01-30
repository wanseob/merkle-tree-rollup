pragma solidity >= 0.6.0;
import { Tree, OPRU, ExtendedOPRU } from "../library/Types.sol";
import { OPRULib } from "../library/OPRULib.sol";
import { MiMCTree } from "../trees/MiMCTree.sol";

contract MiMCOPRU is MiMCTree {
    using OPRULib for *;

    uint constant public CHALLENGE_PERIOD = 15;
    Tree tree;

    struct Proposal {
        OPRU opru;
        address proposer;
        uint challengeDue;
        bool slashed;
    }

    event NewProposal(uint id);
    event NewChallenge(uint id);
    event Slashed(uint opruId, address proposer, address challenger);

    /** Proposals */
    uint index = 0;
    Proposal[] proposals;
    mapping(address=>bool) public slashedProposalters;

    /** Challenges */
    ExtendedOPRU[] rollUps;
    mapping(uint=>mapping(address=>bool)) permitted;


    constructor() public {
        tree = newTree();
    }

    function propose(
        uint startingRoot,
        uint startingIndex,
        uint[] memory leaves,
        uint targetingRoot
    ) public {
        require(!slashedProposalters[msg.sender], "Not allowed to submit");
        proposals.push() = Proposal(
            OPRU(
                Tree(startingRoot, startingIndex),
                Tree(targetingRoot, startingIndex + leaves.length),
                bytes32(0).mergeLeaves(leaves)
            ),
            msg.sender,
            now + CHALLENGE_PERIOD,
            false
        );
        emit NewProposal(proposals.length - 1);
    }

    function finalize(uint id) public {
        Proposal storage proposal = proposals[id];
        require(!proposal.slashed, "Proposal is slashed");
        require(proposal.challengeDue <= now, "Still in the challenge period");
        require(
            proposal.opru.start.root == tree.root &&
            proposal.opru.start.index == tree.index,
            "Current tree is different with the proposal's prev tree"
        );
        tree.root = proposal.opru.result.root;
        tree.index = proposal.opru.result.index;
    }

    function newOPRU(
        uint startingRoot,
        uint startingIndex,
        uint[] memory initialSiblings
    ) public virtual {
        ExtendedOPRU storage opru = rollUps.push();
        hasher().initExtendedOPRU(opru, startingRoot, startingIndex, initialSiblings);
        permitted[rollUps.length - 1][msg.sender] = true;
        emit NewChallenge(rollUps.length - 1);
    }

    /**
     * @dev Update the stored roll up by appending given leaves.
     *      Only the creator is allowed to append new leaves.
     */
    function updateOPRU(
        uint id,
        uint[] memory leaves
    ) public virtual {
        ExtendedOPRU storage opru = rollUps[id];
        require(permitted[id][msg.sender], "Not permitted to update the given storage roll up");
        hasher().update(opru, leaves);
    }

    /**
     * @dev The storage roll up creator can delete it to get refund gas cost.
     */
    function deleteOPRU(uint id) public {
        require(permitted[id][msg.sender], "Not permitted to update the given storage roll up");
        delete rollUps[id];
        delete permitted[id][msg.sender];
    }

    function challenge(uint proposalId, uint rollUpId) public {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.slashed, "Already slashed");
        require(proposal.challengeDue > now, "Not in the challenge period");
        ExtendedOPRU storage extended = rollUps[rollUpId];
        bool verification = extended.opru.verify(
            proposal.opru.start.root,
            proposal.opru.start.index,
            proposal.opru.result.root,
            proposal.opru.mergedLeaves
        );
        if(!verification) {
            // Implement slash logic here
            proposal.slashed = true;
            emit Slashed(proposalId, proposal.proposer, msg.sender);
        }
        deleteOPRU(rollUpId);
    }

    function getProposal(uint id) public view returns (
        uint startingRoot,
        uint startingIndex,
        uint resultRoot,
        uint resultIndex,
        address proposer,
        uint challengeDue,
        bool slashed
    ) {
        Proposal memory proposal = proposals[id];
        return (
            proposal.opru.start.root,
            proposal.opru.start.index,
            proposal.opru.result.root,
            proposal.opru.result.index,
            proposal.proposer,
            proposal.challengeDue,
            proposal.slashed
        );
    }
}

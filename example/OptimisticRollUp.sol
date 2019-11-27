pragma solidity >=0.4.21 <0.6.0;

import { SMT256 } from "../contracts/SMT.sol";

contract OptimisticRollUpExample {
    using SMT256 for bytes32;

    struct OptimisticRollUp {
        bytes32 prevRoot;
        bytes32 nextRoot;
        address submitter;
        uint fee;
        uint challengeDue;
        bool slashed;
    }

    struct Proposer {
        uint stake;
        uint reward;
        uint exitAllowance;
    }

    bytes32 public root;
    uint public challengePeriod;
    uint public minimumStake;
    mapping(address=>Proposer) public proposers;
    mapping(bytes32=>OptimisticRollUp) public candidates;

    constructor(uint _challengePeriod, uint _minimumStake) public {
        challengePeriod = _challengePeriod;
        minimumStake = _minimumStake;
    }

    function register() public payable {
        require(msg.value >= minimumStake, "Should stake more than minimum amount of ETH");
        Proposer storage proposer = proposers[msg.sender];
        proposer.stake += msg.value;
    }

    function deregister() public {
        address payable proposerAddr = msg.sender;
        Proposer storage proposer = proposers[proposerAddr];
        require(proposer.exitAllowance <= block.number, "Still in the challenge period");
        proposerAddr.transfer(proposer.reward + proposer.stake);
        proposer.stake = 0;
        proposer.reward = 0;
    }

    function optimisticRollUp(
        bytes32 prevRoot,
        bytes32 nextRoot,
        bytes32[] memory leaves,
        bytes32[256][] memory siblings
    ) public {
        Proposer storage proposer = proposers[msg.sender];
        // Check permission
        require(proposable(proposer), "Not allowed to propose");
        // Save opru object
        bytes32 id = keccak256(abi.encodePacked(prevRoot, nextRoot, leaves, siblings));
        candidates[id] = OptimisticRollUp(
            prevRoot,
            nextRoot,
            msg.sender,
            0, // We can add fee here for the optimistic roll up submitter
            block.number + challengePeriod,
            false
        );
        // Update exit allowance period
        proposer.exitAllowance = block.number + challengePeriod;
    }

    function finalize(bytes32 id) public {
        // Retrieve optimistic roll up data
        OptimisticRollUp memory opru = candidates[id];
        // Check the optimistic roll up to finalize is pointing the current root correctly
        require(opru.prevRoot == root, "Roll up is pointing different root");
        // Update the current root
        root = opru.nextRoot;
        // Give fee
        Proposer storage proposer = proposers[opru.submitter];
        proposer.reward += opru.fee;
    }

    function challenge(bytes32 prevRoot, bytes32 nextRoot, bytes32[] memory leaves, bytes32[256][] memory siblings) public {
        bytes32 id = keccak256(abi.encodePacked(prevRoot, nextRoot, leaves, siblings));
        OptimisticRollUp storage opru = candidates[id];
        // Check the optimistic roll up is in the challenge period
        require(opru.challengeDue > block.number, "You missed the challenge period");
        // Check it is already slashed
        require(!opru.slashed, "Already slashed");
        // Check the optimistic rollup exists
        require(opru.submitter != address(0), "Not an existing rollup");
        // Check the state transition of the optimistic rollup is invalid
        require(nextRoot != prevRoot.rollUp(leaves, siblings), "Valid roll up");
        // Since every condition of the challenge is passed, slash the submitter
        opru.slashed = true; // Record it as slashed;
        Proposer storage proposer = proposers[opru.submitter];
        proposer.stake = 0;
        proposer.reward = 0;
    }

    function proposable(address proposerAddr) public view returns (bool) {
        return proposable(proposers[proposerAddr]);
    }

    function proposable(Proposer memory  proposer) internal view returns (bool) {
        // You can add more consensus logic here
        if(proposer.stake <= minimumStake) {
            return false;
        } else {
            return true;
        }
    }
}

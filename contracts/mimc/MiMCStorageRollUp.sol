pragma solidity >= 0.6.0;

import { StorageRollUp } from "../RollUpLib.sol";
import { StorageRollUpBase } from "../StorageRollUpBase.sol";
import { MiMCRollUp } from "./MiMCRollUp.sol";

contract MiMCStorageRollUp is StorageRollUpBase, MiMCRollUp {
    struct Challenge {
        address creator;
        StorageRollUp rollUp;
    }

    mapping(uint=>Challenge) challenges;
    uint index;

    constructor() public {
    }

    function newChallenge(
        uint startingRoot,
        uint startingIndex,
        uint[] memory initialSiblings
    ) public {
        uint id = index;
        Challenge storage challenge = challenges[id];
        initStorageRollUp(challenge.rollUp, startingRoot, startingIndex, initialSiblings);
        challenge.creator = msg.sender;
        index += 1;
    }

    function updateChallenge(
        uint id,
        uint[] memory leaves
    ) public {
        Challenge storage challenge = challenges[id];
        require(msg.sender == challenge.creator, "Only allowed to the challenge creater");
        rollUpAndStore(challenge.rollUp, leaves);
    }

    function resultChallenge(
        uint id,
        uint startingRoot,
        uint startingIndex,
        uint targetingRoot,
        uint[] memory leaves
    ) public view returns (bool) {
        Challenge storage challenge = challenges[id];
        return resultStorageRollUp(challenge.rollUp, startingRoot, startingIndex, targetingRoot, leaves);
    }
}

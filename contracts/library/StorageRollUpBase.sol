pragma solidity >= 0.6.0;

import { Hasher, StorageRollUp } from "./Types.sol";
import { StorageRollUpLib } from "./StorageRollUpLib.sol";
import { RollUpTree } from "./RollUpTree.sol";

/**
 * @title Base contract of storage based roll up implementation
 * @dev When the gas cost is expensive too much, we can accomplish the roll up
 *      through multiple transactions. Especially if the hash cost exceeds 5000 gas,
 *      it becomes cheaper to store intermediate siblings than validating siblings 
 *      every time to continue the preceding roll ups.
 */
abstract contract StorageRollUpBase is RollUpTree {
    using StorageRollUpLib for StorageRollUp;
    using StorageRollUpLib for Hasher;

    mapping(uint=>StorageRollUp) rollUps;
    uint index;

    constructor() public {
    }

    function newRollUp(
        uint startingRoot,
        uint startingIndex,
        uint[] memory initialSiblings
    ) public virtual returns (uint id){
        id = index;
        StorageRollUp storage rollUp = rollUps[id];
        hasher().initStorageRollUp(rollUp, startingRoot, startingIndex, initialSiblings);
        rollUp.manager = msg.sender;
        index += 1;
    }

    function append(
        uint id,
        uint[] memory leaves
    ) public virtual {
        StorageRollUp storage rollUp = rollUps[id];
        require(msg.sender == rollUp.manager, "Update is only allowed to the rollUp creater");
        hasher().appendToStorageRollUp(rollUp, leaves);
    }

    /**
     * @return It returns true when the roll up is valid.
     */
    function verifyRollUp(
        uint rollUpId,
        uint startingRoot,
        uint startingIndex,
        uint[] memory leaves,
        uint targetingRoot
    ) public view returns (bool) {
        StorageRollUp storage rollUp = rollUps[rollUpId];
        return rollUp.verify(startingRoot, startingIndex, leaves, targetingRoot);
    }
}

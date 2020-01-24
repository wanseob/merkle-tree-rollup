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
    using StorageRollUpLib for bytes32;

    event NewStorageRollUp(uint id);

    mapping(uint=>StorageRollUp) rollUps;
    mapping(uint=>mapping(address=>bool)) permitted;
    uint sRollUpIndex;

    constructor() public {
    }

    /**
     * @dev Create a new roll up object and store it. It requires the valid
     *      sibling data to start the roll up. The starting leaf and every leaf
     *      behind that should be the empty leaves.
     */
    function newRollUp(
        uint startingRoot,
        uint startingIndex,
        uint[] memory initialSiblings
    ) public virtual returns (uint id){
        id = sRollUpIndex++;
        StorageRollUp storage rollUp = rollUps[id];
        hasher().initStorageRollUp(rollUp, startingRoot, startingIndex, initialSiblings);
        permitted[id][msg.sender] = true;
        emit NewStorageRollUp(id);
    }

    /**
     * @dev Update the storage roll up by appending given leaves.
     *      Only the creator is allowed to append new leaves.
     */
    function append(
        uint rollUpId,
        uint[] memory leaves
    ) public virtual {
        StorageRollUp storage rollUp = rollUps[rollUpId];
        require(permitted[rollUpId][msg.sender], "Not permitted to update the given storage roll up");
        hasher().appendToStorageRollUp(rollUp, leaves);
    }

    /**
     * @return It returns the validity of the storage roll up
     */
    function verifyRollUp(
        uint rollUpId,
        uint startingRoot,
        uint startingIndex,
        uint targetingRoot,
        uint[] memory leaves
    ) public view returns (bool) {
        StorageRollUp storage rollUp = rollUps[rollUpId];
        bytes32 mergedLeaves = bytes32(0).mergeLeaves(leaves);
        return rollUp.verify(startingRoot, startingIndex, targetingRoot, mergedLeaves);
    }

    /**
     * @return It returns the validity of the storage roll up
     */
    function verifyRollUp(
        uint rollUpId,
        uint startingRoot,
        uint startingIndex,
        uint targetingRoot,
        bytes32 mergedLeaves
    ) internal view returns (bool) {
        StorageRollUp storage rollUp = rollUps[rollUpId];
        return rollUp.verify(startingRoot, startingIndex, targetingRoot, mergedLeaves);
    }
}

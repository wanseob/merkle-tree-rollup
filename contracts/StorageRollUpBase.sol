pragma solidity >= 0.6.0;

import { Hasher, RollUpLib, StorageRollUp } from "./RollUpLib.sol";
import { RollUpBase } from "./RollUpBase.sol";

abstract contract StorageRollUpBase is RollUpBase {
    using RollUpLib for Hasher;
    using RollUpLib for StorageRollUp;

    function initStorageRollUp(
        StorageRollUp storage sRollUp,
        uint startingRoot,
        uint startingIndex,
        uint[] memory initialSiblings
    ) internal {
        sRollUp.initStorageRollUp(hasher(), startingRoot, startingIndex, initialSiblings);
    }

    function rollUpAndStore(
        StorageRollUp storage sRollUp,
        uint[] memory leaves
    ) internal {
        sRollUp.rollUpAndStore(hasher(), leaves);
    }

    function resultStorageRollUp(
        StorageRollUp memory sRollUp,
        uint startingRoot,
        uint startingIndex,
        uint targetingRoot,
        uint[] memory leaves
    ) internal pure returns (bool) {
        return sRollUp.resultStorageRollUp(
            startingRoot,
            startingIndex,
            leaves,
            targetingRoot
        );
    }
}

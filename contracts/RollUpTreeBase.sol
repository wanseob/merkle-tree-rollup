pragma solidity >= 0.6.0;

import { Tree } from "./RollUpLib.sol";
import { RollUpBase } from "./RollUpBase.sol";

abstract contract RollUpTreeBase is RollUpBase {
    function initTree(
        Tree storage tree
    ) internal {
        uint[] memory zeroes = preHashedZero();
        tree.root = zeroes[zeroes.length - 1];
        tree.index = 0;
    }

    function push(
        Tree storage tree,
        uint[] memory leaves, 
        uint[] memory initialSiblings
    ) internal {
        uint newRoot = rollUp(tree.root, tree.index, leaves, initialSiblings);
        tree.root = newRoot;
        tree.index += leaves.length;
    }
}

pragma solidity >= 0.6.0;

import { Tree } from "../library/Types.sol";
import { MiMCTree } from "../trees/MiMCTree.sol";

contract MiMCExample is MiMCTree {
    Tree public tree;

    constructor() public {
        tree = newTree();
    }

    function push(
        uint[] memory leaves,
        uint[] memory initialSiblings
    ) public {
        uint newRoot = rollUp(tree.root, tree.index, leaves, initialSiblings);
        tree.root = newRoot;
        tree.index += leaves.length;
    }
}

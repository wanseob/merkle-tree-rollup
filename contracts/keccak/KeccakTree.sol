pragma solidity >= 0.6.0;

import { Tree, Hasher, RollUpLib } from "../RollUpLib.sol";
import { RollUpTreeBase } from "../RollUpTreeBase.sol";
import { KeccakRollUp } from "./KeccakRollUp.sol";

contract KeccakTree is RollUpTreeBase, KeccakRollUp {
    using RollUpLib for Tree;

    Tree public tree;

    constructor() public {
        initTree(tree);
    }

    function push(
        uint[] memory leaves,
        uint[] memory initialSiblings
    ) public {
        push(tree, leaves, initialSiblings);
    }
}

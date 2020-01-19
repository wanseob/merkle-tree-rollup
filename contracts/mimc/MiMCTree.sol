pragma solidity >= 0.6.0;

import { RollUpTreeBase } from "../RollUpTreeBase.sol";
import { Tree, RollUpLib } from "../RollUpLib.sol";
import { MiMCRollUp } from "./MiMCRollUp.sol";

library MiMC {
    /**
     * @dev This is a dummy implementation for contract compilation
     * We'll use a generated library by circomlib instead of this dummy library
     * Please see
     * 1. migrations/2_deploy_mimc.js
     * 2. https://github.com/iden3/circomlib/blob/master/src/mimcsponge_gencontract.js
     */
    function MiMCSponge(uint256 in_xL, uint256 in_xR, uint256 in_k) external pure returns (uint256 xL, uint256 xR) {

    }
}

contract MiMCTree is RollUpTreeBase, MiMCRollUp {
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

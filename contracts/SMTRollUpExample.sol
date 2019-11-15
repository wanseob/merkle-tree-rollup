pragma solidity >= 0.5.0 < 0.6.0;

import { SMT256 } from "./SMT.sol";

/**
 * @author Wilson Beam <wilsonbeam@protonmail.com>
 * @title Sparse Merkle Tree for optimistic roll up
 *
 * @dev Append only purpose Sparse Merkle Tree solidity library for optimistic roll up
 */
contract SMT256RollUp {
    using SMT256 for bytes32;
    bytes32 root;

    constructor() public {

    }

    function rollUp() public returns (bool) {

    }
}

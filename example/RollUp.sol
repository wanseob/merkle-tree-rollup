pragma solidity >=0.4.21 <0.6.0;

import { SMT256 } from "../contracts/SMT.sol";


contract RollUpExample {
    using SMT256 for bytes32;

    bytes32 public root;
    
    function rollUp(bytes32[] memory leaves, bytes32[256][] memory siblings) public {
        root = root.rollUp(leaves, siblings);
    }
}

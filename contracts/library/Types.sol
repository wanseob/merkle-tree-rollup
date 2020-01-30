pragma solidity >= 0.6.0;

struct Hasher {
    function (uint, uint) internal pure returns (uint) parentOf;
    uint[] preHashedZero;
}

struct Tree {
    uint root;
    uint index;
}

struct OPRU {
    Tree start;
    Tree result;
    bytes32 mergedLeaves;
}

struct ExtendedOPRU {
    OPRU opru;
    uint[] siblings;
}

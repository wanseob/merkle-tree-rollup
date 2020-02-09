pragma solidity >= 0.6.0;

struct Hasher {
    function (uint, uint) internal pure returns (uint) parentOf;
    uint[] preHashedZero;
}

struct Tree {
    uint root;
    uint index;
}

/**
 * @dev This struct is appropriate for cheap hash functions.
 *      If you use OPRU struct, you need to provide the siblings data to
 *      append new items. The hash result using the submitted siblings should be
 *      matched with the last result root and its index.
 */
struct OPRU {
    Tree start;
    Tree result;
    bytes32 mergedLeaves;
}

/**
 * @dev This struct is appropriate for expensive hash functions.
 *      If you use ExtendedOPRU struct, you need to provide the siblings data
 *      when only you start the roll up. And then it will store the intermediate
 *      siblings data on chain. Therefore, it allows us to skip the expensive hash
 *      calculations because there's no need to veify the validity of the siblings.
 *      Simply, if hash cost is expensive than 5000, just use this struct.
 *      In more detail, use ExtendedOPRU when v > 5000 + 20000/(n-1)
 *      v: gas cost of the hash function, n: how many times to roll up
 */
struct ExtendedOPRU {
    OPRU opru;
    uint[] siblings;
}

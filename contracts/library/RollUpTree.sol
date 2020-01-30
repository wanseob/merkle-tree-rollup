pragma solidity >= 0.6.0;

import { Hasher, Tree } from "./Types.sol";
import { RollUpLib } from "./RollUpLib.sol";

/**
 * @title Base contract of roll up implementation
 * @dev With this base, you can only implement append only merkle tree.
 *      To get the update function, you should use sparse merkle tree.
 *      Please see https://github.com/wilsonbeam/smt-rollup
 */
abstract contract RollUpTree {
    using RollUpLib for Hasher;

    /**
     * @param prevRoot The previous root of the merkle tree
     * @param index The index where new leaves start
     * @param leaves Items to append to the merkle tree
     * @param initialSiblings Sibling data for the merkle proof of the prevRoot
     * @return new root after appending the given leaves
     */
    function rollUp(
        uint prevRoot,
        uint index,
        uint[] memory leaves,
        uint[] memory initialSiblings
    ) public pure returns (uint) {
        return hasher().rollUp(prevRoot, index, leaves, initialSiblings);
    }

    /**
     * @param root The roof of a merkle tree
     * @param leaf The leaf to prove the membership
     * @param index Where the leaf is located in
     * @param siblings The sibling data of the given leaf
     * @return proof result in boolean
     */
    function merkleProof(
        uint root,
        uint leaf,
        uint index,
        uint[] memory siblings
    ) public pure returns (bool) {
        return hasher().merkleProof(root, leaf, index, siblings);
    }

    function newTree() internal pure returns (Tree memory) {
        return hasher().newTree();
    }

    /**
     * @dev Internal function to use RollUpLib. To use this function, the contract
     *      should implement parentOf() and preHashedZero() first
     */
    function hasher() internal pure returns (Hasher memory) {
        return Hasher(parentOf, preHashedZero());
    }

    /**
     * @dev You should implement how to calculate the branch node. The implementation
     *      can be differ by which hash function you use.
     */
    function parentOf(uint left, uint right) public virtual pure returns (uint);

    /**
     * @dev Merkle tree for roll up consists of empty leaves at first. Therefore you
     *      can reduce the hash cost by using hard-coded pre hashed zero value arrays.
     *      If you want to use a merkle tree which depth is 4, you should return a hard coded
     *      array of uint which length is 5. And the value should be equivalent to the following
     *      [0, hash(0, 0), hash(hash(0,0, hash(0,0)))...]
     */
    function preHashedZero() public virtual pure returns (uint[] memory preHashed);
}

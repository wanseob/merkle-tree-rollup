pragma solidity >= 0.5.0 < 0.6.0;


/**
 * @author Wilson Beam <wilsonbeam@protonmail.com>
 * @title Sparse Merkle Tree for optimistic roll up
 *
 * @dev Append only purpose Sparse Merkle Tree solidity library for optimistic roll up
 */
library SMT256 {
    // in Solidity: keccak256('exist')
    // in Web3JS: soliditySha3('exist')
    bytes32 constant public EXIST = 0xb0b4e07bb5592f3d3821b2c1331b436763d7be555cf452d6c6836f74d5201e85;
    // in Solidity: keccak256(abi.encodePacked(bytes32(0)))
    // in Web3JS: soliditySha3(0)
    bytes32 constant public NON_EXIST = 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563;

    function inclusionProof(
        bytes32 root,
        bytes32 nullifier,
        bytes32[255] memory siblings
    ) internal pure returns(bool) {
        return merkleProof(root, nullifier, EXIST, siblings);
    }

    function nonInclusionProof(
        bytes32 root,
        bytes32 nullifier,
        bytes32[255] memory siblings
    ) internal pure returns(bool) {
        return merkleProof(root, nullifier, NON_EXIST, siblings);
    }

    function merkleProof(
        bytes32 root,
        bytes32 leaf,
        bytes32 value,
        bytes32[255] memory siblings
    ) internal pure returns(bool) {
        bytes32 cursor = value;
        uint path = uint(leaf);
        for (uint8 i = 0; i < siblings.length; i++) {
            if (path % 2 == 0) {
                // Right sibling
                cursor = keccak256(abi.encodePacked(cursor, siblings[i]));
            } else {
                // Left sibling
                cursor = keccak256(abi.encodePacked(siblings[i], cursor));
            }
            path = path >> 1;
        }
        require(cursor == root, "Invalid merkle proof");
        return true;
    }

    function rollUp1(
        bytes32 root,
        bytes32 nextRoot,
        bytes32 nullifier,
        bytes32[255] memory siblings
    ) internal pure returns (bytes32) {
        require(root != nextRoot, "Nullifier should update the root");
        require(nonInclusionProof(root, nullifier, siblings), "Prev root is invalid for the nullifier and its sibling");
        require(inclusionProof(nextRoot, nullifier, siblings), "Next root is invalid for the nullifier and its sibling");
        return nextRoot;
    }

    function rollUp16(
        bytes32 root,
        bytes32[16] memory nextRoots,
        bytes32[16] memory nullifiers,
        bytes32[255][16] memory siblings
    ) internal pure returns (bytes32) {
        bytes32 cursor = root;
        for (uint8 i = 0; i < 16; i ++) {
            cursor = rollUp1(cursor, nextRoots[i], nullifiers[i], siblings[i]);
        }
        return cursor;
    }

    function rollUp32(
        bytes32 root,
        bytes32[32] memory nextRoots,
        bytes32[32] memory nullifiers,
        bytes32[255][32] memory siblings
    ) internal pure returns (bytes32) {
        bytes32 cursor = root;
        for (uint8 i = 0; i < 32; i ++) {
            cursor = rollUp1(root, nextRoots[i], nullifiers[i], siblings[i]);
        }
        return cursor;
    }

    function rollUp64(
        bytes32 root,
        bytes32[64] memory nextRoots,
        bytes32[64] memory nullifiers,
        bytes32[255][64] memory siblings
    ) internal pure returns (bytes32) {
        bytes32 cursor = root;
        for (uint8 i = 0; i < 64; i ++) {
            cursor = rollUp1(root, nextRoots[i], nullifiers[i], siblings[i]);
        }
        return cursor;
    }
}

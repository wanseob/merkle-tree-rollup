pragma solidity >= 0.6.0;

struct Tree {
    uint root;
    uint index;
}

struct StorageRollUp {
    bool initialized;
    Tree start;
    Tree result;
    bytes32 mergedLeaves;
    uint[] siblings;
}

struct Hasher {
    function (uint, uint) internal pure returns (uint) parentOf;
    uint[] preHashedZero;
}

/**
 * @author Wilson Beam <wilsonbeam@protonmail.com>
 * @title Merkle Tree for optimistic roll up using MiMC hash
 */
library RollUpLib {
    function rollUp(
        Hasher memory self,
        uint startingRoot,
        uint index,
        uint[] memory leaves,
        uint[] memory initialSiblings
    ) internal pure returns (uint newRoot) {
        require(startingLeafProof(self, startingRoot, index, initialSiblings), "Invalid merkle proof of starting leaf node");
        uint nextIndex = index;
        uint[] memory nextSiblings = initialSiblings;
        for(uint i = 0; i < leaves.length; i++) {
            (newRoot, nextIndex, nextSiblings) = _append(self, nextIndex, leaves[i], nextSiblings);
        }
    }

    /**
     * @dev When the hash function is very expensive, a roll up can be accomplished through
     * multiple transactions. If the hash function is more expensive than 5,000 gas it is 
     * effective to use storage than veritying the initial siblings everytime.
     */ 
    function initStorageRollUp(
        StorageRollUp storage self,
        Hasher memory hasher,
        uint startingRoot,
        uint index,
        uint[] memory initialSiblings
   ) internal {
        require(!self.initialized, "Already initialized");
        require(startingLeafProof(hasher, startingRoot, index, initialSiblings), "Invalid merkle proof of starting leaf node");
        self.start.root= startingRoot;
        self.result.root = startingRoot;
        self.start.index = index;
        self.result.index = index;
        self.mergedLeaves = bytes32(0);
        for(uint i = 0; i < initialSiblings.length; i++) {
            self.siblings[i] = initialSiblings[i];
        }
    }

    function rollUpAndStore(
        StorageRollUp storage self,
        Hasher memory hasher,
        uint[] memory leaves
    ) internal {
        require(self.initialized, "Not initialized");
        uint nextIndex = self.result.index;
        bytes32 mergedLeaves = self.mergedLeaves;
        uint[] memory nextSiblings = self.siblings;
        uint newRoot;
        for(uint i = 0; i < leaves.length; i++) {
            (newRoot, nextIndex, nextSiblings) = _append(hasher, nextIndex, leaves[i], nextSiblings);
            mergedLeaves = keccak256(abi.encodePacked(mergedLeaves, leaves[i]));
        }
        for(uint i = 0; i < nextSiblings.length; i++) {
            self.siblings[i] = nextSiblings[i];
        }
        self.mergedLeaves = mergedLeaves;
        self.result.root = newRoot;
        self.result.index = nextIndex;
    }

    function resultStorageRollUp(
        StorageRollUp memory self,
        uint startingRoot,
        uint startingIndex,
        uint[] memory leaves,
        uint targetingRoot
    ) internal pure returns (bool) {
        require(self.initialized, "Not an initialized storage roll up");
        require(self.start.root == startingRoot, "Starting root is different");
        require(self.start.index == startingIndex, "Starting index is different");
        bytes32 mergedLeaves;
        for(uint i = 0; i < leaves.length; i ++) {
            mergedLeaves = keccak256(abi.encodePacked(mergedLeaves, leaves[i]));
        }
        require(self.mergedLeaves == mergedLeaves, "Appended leaves are different");
        return self.result.root == targetingRoot;
    }

    function _append(
        Hasher memory self,
        uint index,
        uint leaf,
        uint[] memory siblings
    ) private pure returns(
        uint nextRoot,
        uint nextIndex,
        uint[] memory nextSiblings
    ) {
        nextSiblings = new uint[](siblings.length);
        uint path = index;
        uint node = leaf;
        for(uint i = 0; i < siblings.length; i++) {
            if(path & 1 == 0) {
                // right empty sibling
                nextSiblings[i] = node; // current node will be the next merkle proof's left sibling
                node = self.parentOf(node, self.preHashedZero[i]);
            } else {
                // left sibling
                nextSiblings[i] = siblings[i]; // keep current sibling
                node = self.parentOf(siblings[i], node);
            }
            path >>= 1;
        }
        nextRoot = node;
        nextIndex = index + 1;
    }

    function merkleRoot(
        Hasher memory self,
        uint leaf,
        uint index,
        uint[] memory siblings
    ) internal pure returns (uint) {
        uint path = index;
        uint node = leaf;
        for(uint i = 0; i < siblings.length; i++) {
            if(path & 1 == 0) {
                // right sibling
                node = self.parentOf(node, siblings[i]);
            } else {
                // left sibling
                node = self.parentOf(siblings[i], node);
            }
            path >>= 1;
        }
        return node;
    }


    function merkleProof(
        Hasher memory self,
        uint root,
        uint leaf,
        uint index,
        uint[] memory siblings
    ) internal pure returns (bool) {
        return merkleRoot(self, leaf, index, siblings) == root;
    }

    function startingLeafProof(
        Hasher memory self,
        uint root,
        uint index,
        uint[] memory siblings
    ) internal pure returns (bool) {
        uint[] memory siblingsOflastLeaf = siblings;
        uint path = index;
        uint preHashedZero;
        for(uint i = 0; i < siblings.length; i++) {
            preHashedZero = self.preHashedZero[i];
            if(path & 1 == 0) {
                // Right sibling should be a prehashed zero
                if(siblings[i] != preHashedZero) return false;
            } else {
                // Left sibling should not be a prehashed zero
                if(siblings[i] == preHashedZero) return false;
            }
            path >>= 1;
        }
        return merkleProof(self, root, index, self.preHashedZero[0], siblingsOflastLeaf);
    }
}

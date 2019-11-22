import { soliditySha3, Hex, toBN } from 'web3-utils';
import BN from 'bn.js';
import RocksDB from 'level-rocksdb';
import { keccak256PreHash } from './keccak256PreHash';
import fs from 'fs';

export interface PreHash {
  [details: number]: string;
}

export interface Hasher {
  hash(val: Hex): Hex;
  combinedHash(left: Hex, right: Hex): Hex;
  preHash: PreHash;
}

export interface MerkleProof {
  root: Hex;
  leaf: Hex;
  val: Hex;
  siblings: Hex[];
}

export interface SMT {
  depth: number;
  hasher: Hasher;
  root(): Promise<Hex>;
  updateLeaf(leaf: Hex, val: Hex): Promise<MerkleProof>;
  merkleProof(leaf: Hex): Promise<MerkleProof>;
  verityProof(proof: MerkleProof): boolean;
  // exist(leaf: Hex): Promise<boolean>;
}

export const solidityHasher = {
  hash(val: Hex): Hex {
    return soliditySha3(val);
  },
  combinedHash(left: Hex, right: Hex): Hex {
    return soliditySha3(left, right);
  },
  preHash: keccak256PreHash
};

export const verifyProof = (proof: MerkleProof) => {
  let path = '1' + toBN(proof.leaf).toString(2, proof.siblings.length);
};

/**
 * Sparse Merkle Tree implementation manages only the existence of nullifiers.
 */
export class SparseMerkleTree implements SMT {
  readonly depth: number;
  readonly location: string;
  readonly leafPrefix: BN;
  rootNode: Hex;
  rootLock: Boolean;
  hasher: Hasher;
  nodes: RocksDB;
  values: RocksDB;
  /**
   * Init a Sparse Merkle Tree
   * @param {number} depth
   * @param {Array} leaves
   */
  constructor(depth: number, location: string, hasher?: Hasher) {
    this.depth = depth;
    this.hasher = hasher ? hasher : solidityHasher;
    this.location = location;
    if (!fs.existsSync(location)) {
      fs.mkdirSync(location);
    }
    this.nodes = RocksDB(location + '/node');
    this.values = RocksDB(location + '/values');
    this.leafPrefix = new BN(1).shln(depth);
    this.rootNode = null;
    this.rootLock = false;
  }

  async root(): Promise<Hex> {
    if (this.rootNode == null) {
      this.rootNode = (await this.getNodeHash(new BN(1))).toString();
    }
    if (this.rootLock) {
      throw Error('SMT is updating the root');
    }
    return this.rootNode;
  }

  getValue(leaf: Hex): Promise<RocksDB.Bytes> {
    return new Promise<RocksDB.Bytes>(async resolve => {
      let leafNodeHash = await this.getNodeHash(this.leafPrefix.add(toBN(leaf)));
      if (leafNodeHash === this.hasher.preHash[0]) {
        resolve('0');
      } else {
        this.values.get(leafNodeHash, (err, val) => {
          if (!err) {
            resolve(val);
          } else if (err.name == 'NotFoundError') {
            resolve('0');
          } else {
            throw err;
          }
        });
      }
    });
  }
  async merkleProof(leaf: Hex): Promise<MerkleProof> {
    let rightSibling = false;
    let cursor = this.leafPrefix.add(toBN(leaf));
    let siblings: Hex[] = [];
    let sibling: Hex;
    do {
      rightSibling = cursor.isEven();
      sibling = (await this.getNodeHash(cursor.add(rightSibling ? new BN(1) : new BN(-1)))).toString();
      siblings.push(sibling);
      cursor = cursor.shrn(1);
    } while (!cursor.shrn(1).isZero());
    let proof: MerkleProof = {
      leaf,
      val: (await this.getValue(leaf)).toString(),
      root: await this.root(),
      siblings
    };
    if (!this.verityProof(proof)) throw Error('Generated invalid proof');
    return proof;
  }

  verityProof(proof: MerkleProof): boolean {
    let cursor: BN = this.leafPrefix.add(toBN(proof.leaf));
    let leafHash = this.hasher.hash(proof.val);
    let root = leafHash;
    let rightSibling: boolean;
    let sibling: Hex;
    do {
      rightSibling = cursor.isEven();
      sibling = proof.siblings[proof.siblings.length - (cursor.bitLength() - 1)];
      root = rightSibling ? this.hasher.combinedHash(root, sibling) : this.hasher.combinedHash(sibling, root);
      cursor = cursor.shrn(1);
    } while (!cursor.shrn(1).isZero());
    return root === proof.root;
  }

  async updateLeaf(leaf: Hex, val: Hex): Promise<MerkleProof> {
    // Lock the root mutation
    this.lock();
    // Put exist hash value to the
    let leafNode = this.leafPrefix.add(toBN(leaf));
    let leafNodeValue = soliditySha3(val);
    // Store the value
    await this.storeValue(soliditySha3(val), val.toString());
    // Update parent nodes
    await this.updateNode(leafNode, leafNodeValue);
    this.rootNode = await this.updateNodeRecursively(leafNode, leafNodeValue);
    // Unlock the root mutation
    this.unlock();
    return this.merkleProof(leaf);
  }

  private lock() {
    if (this.rootLock) {
      throw Error('Already locked');
    }
    this.rootLock = true;
  }

  private unlock() {
    if (!this.rootLock) {
      throw Error('Nothing to unlock');
    }
    this.rootLock = false;
  }

  private async updateNodeRecursively(child: BN, val: Hex): Promise<Hex> {
    // Get parent node's path index
    let parentNode = child.shrn(1); // child >> 1
    if (parentNode.isZero()) {
      // Arrived to the root. Stop the recursive calculation.
      return val;
    } else {
      // Get sibling
      let hasRightSibilng = child.isEven();
      let siblingIndex = child.add(hasRightSibilng ? new BN(1) : new BN(-1));
      let sibling: Hex = (await this.getNodeHash(siblingIndex)).toString();
      // Calculate the parent hash with the sibling
      let parentHash = hasRightSibilng ? soliditySha3(val, sibling) : soliditySha3(sibling, val);
      // Update parent node hash value
      await this.updateNode(parentNode, parentHash);
      // Recursively update parents
      return await this.updateNodeRecursively(parentNode, parentHash);
    }
  }

  private async updateNode(index: BN, val: RocksDB.Bytes): Promise<boolean> {
    return new Promise<boolean>(resolve => {
      this.nodes.put(index.toString(), val, err => {
        if (err) {
          // throw err;
          resolve(false);
        } else {
          resolve(true);
        }
      });
    });
  }

  private storeValue(key: RocksDB.Bytes, val: RocksDB.Bytes): Promise<boolean> {
    return new Promise<boolean>(resolve => {
      this.values.put(key, val, err => {
        if (err) {
          // throw err;
          resolve(false);
        } else {
          resolve(true);
        }
      });
    });
  }

  private getNodeHash(key: BN): Promise<RocksDB.Bytes> {
    return new Promise<RocksDB.Bytes>(resolve => {
      this.nodes.get(key.toString(), (err, val) => {
        if (err) {
          if (err.name == 'NotFoundError') {
            let height = this.depth - (key.bitLength() - 1);
            resolve(this.hasher.preHash[height]);
          } else {
            throw err;
          }
        } else {
          resolve(val);
        }
      });
    });
  }
}

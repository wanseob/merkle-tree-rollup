import { Hex } from 'web3-utils';

import { SparseMerkleTree, Hasher, Proof } from './sparseMerkleTree';

export interface RollUpProof {
  root: Hex;
  nullifier: Hex;
  nextRoot: Hex;
  siblings: Hex[];
}

export interface BatchRollUpProof {
  root: Hex;
  nullifiers: Hex[];
  nextRoots: Hex[];
  siblings: Hex[][];
}

export interface BatchResult {
  failures: Hex[];
  batchRollUpProof: BatchRollUpProof;
}

export class NullifierTree extends SparseMerkleTree {
  public readonly NON_EXIST: string;
  public readonly EXIST: string;

  constructor(depth: number, location: string, hasher?: Hasher) {
    super(depth, location, hasher);
    this.NON_EXIST = '0'; // soliditySha3(0)
    this.EXIST = 'exist'; //soliditySha3('exist')
  }

  async addNullifier(nullifier: Hex): Promise<RollUpProof> {
    let nonInclusionProof: Proof = await this.merkleProof(nullifier);
    if (nonInclusionProof.val != '0') {
      throw Error('Already existing nullifier');
    }
    let newRoot = await this.updateLeaf(nullifier, this.EXIST);
    return {
      root: nonInclusionProof.root,
      nullifier,
      nextRoot: newRoot,
      siblings: nonInclusionProof.siblings
    };
  }

  async revertNullifier(nullifier: Hex): Promise<Hex> {
    let newRoot = await this.updateLeaf(nullifier, this.NON_EXIST);
    return newRoot;
  }

  async batchAddNullifiers(nullifiers: Hex[]): Promise<BatchResult> {
    let failures = [];
    let root = await this.root();
    let validNullifiers = [];
    let nextRoots = [];
    let siblings = [];
    for (let nullifier of nullifiers) {
      try {
        let rollUpProof = await this.addNullifier(nullifier);
        validNullifiers.push(rollUpProof.nullifier);
        nextRoots.push(rollUpProof.nextRoot);
        siblings.push(rollUpProof.siblings);
      } catch {
        failures.push(nullifier);
      }
    }
    return {
      failures,
      batchRollUpProof: {
        root,
        nullifiers: validNullifiers,
        nextRoots,
        siblings
      }
    };
  }

  async dryRunBatchAddNullifiers(nullifiers: Hex[]): Promise<BatchResult> {
    /**
     * TODO using database snapshot will be better
     */
    let result: BatchResult = await this.batchAddNullifiers(nullifiers);
    for (let nullifier of nullifiers) {
      await this.revertNullifier(nullifier);
    }
    return result;
  }
}

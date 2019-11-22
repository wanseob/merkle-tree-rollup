import { Hex } from 'web3-utils';

import { SparseMerkleTree, Hasher, MerkleProof } from './sparseMerkleTree';

export interface RollUpProof {
  root: Hex;
  nextRoot: Hex;
  leaves: Hex[];
  siblings: Hex[][];
}

export interface RollUpResult {
  failures: Hex[];
  proof: RollUpProof;
}

export class RollUpSMT extends SparseMerkleTree {
  public readonly NON_EXIST: string;
  public readonly EXIST: string;

  constructor(depth: number, location: string, hasher?: Hasher) {
    super(depth, location, hasher);
    this.NON_EXIST = '0'; // soliditySha3(0)
    this.EXIST = 'exist'; //soliditySha3('exist')
  }

  async exists(leaf: Hex): Promise<boolean> {
    let nonInclusionProof: MerkleProof = await this.merkleProof(leaf);
    return nonInclusionProof.val != '0';
  }

  async append(leaf: Hex): Promise<MerkleProof> {
    if (await this.exists(leaf)) {
      throw Error('Already existing leaf');
    }
    return await this.updateLeaf(leaf, this.EXIST);
  }

  async remove(leaf: Hex): Promise<void> {
    if (!(await this.exists(leaf))) {
      throw Error('Does not exist');
    }
    await this.updateLeaf(leaf, this.NON_EXIST);
  }

  async rollUp(leaves: Hex[]): Promise<RollUpResult> {
    let failures = [];
    let root = await this.root();
    let success = [];
    let siblings = [];
    for (let leaf of leaves) {
      try {
        let proof: MerkleProof = await this.append(leaf);
        success.push(leaf);
        siblings.push(proof.siblings);
      } catch {
        failures.push(leaf);
      }
    }
    let nextRoot = await this.root();
    return {
      failures,
      proof: {
        root,
        nextRoot,
        leaves: success,
        siblings
      }
    };
  }

  async dryRunRollUp(leaves: Hex[]): Promise<RollUpResult> {
    /**
     * TODO using database snapshot will be better
     */
    let result: RollUpResult = await this.rollUp(leaves);
    for (let leaf of leaves) {
      await this.remove(leaf);
    }
    return result;
  }
}

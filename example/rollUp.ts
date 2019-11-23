import { soliditySha3 } from 'web3-utils';
import { RollUpSMT } from 'smt-rollup';

const location = 'testDB';
let nullifierTree: RollUpSMT;
nullifierTree = new RollUpSMT(256, location);
let nullifiers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16].map(i => soliditySha3(i));

async function example() {
  // Retrieve current root
  let root1 = await nullifierTree.root();
  // Dry run returns the proof for the solidity
  let proof1 = await nullifierTree.dryRunRollUp(nullifiers);
  // Dry run does not update the tree
  let root2 = await nullifierTree.root();
  if (root1 != root2) throw Error();
  // Roll up updates the tree
  let proof2 = await nullifierTree.rollUp(nullifiers);
  let root3 = await nullifierTree.root();
  // Return the merkle proof
  let merkleProof = await nullifierTree.merkleProof(nullifiers[0]);
}

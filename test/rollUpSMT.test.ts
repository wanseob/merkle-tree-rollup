import { keccak256PreHash } from '../src/keccak256PreHash';
import { soliditySha3 } from 'web3-utils';
import chai from 'chai';
import fs from 'fs-extra';
import { RollUpSMT } from '../src/rollUpSMT';

const expect = chai.expect;

describe('NullifierTree', () => {
  const location = 'testDB';
  let nullifierTree: RollUpSMT;

  before(() => {
    // Initialize the test purpose database directory
    if (fs.existsSync(location)) {
      fs.removeSync(location);
    }
    fs.mkdirSync(location);
    nullifierTree = new RollUpSMT(256, location);
  });
  after(() => {
    // Remove the test purpose database
    if (fs.existsSync(location)) {
      fs.removeSync(location);
    }
  });
  it('should return its existence correctly', async () => {
    let nullifier = soliditySha3(412);
    let merkleProof1 = await nullifierTree.merkleProof(nullifier);
    expect(merkleProof1.val).to.equal('0');
    await nullifierTree.append(nullifier);
    let merkleProof2 = await nullifierTree.merkleProof(nullifier);
    expect(merkleProof2.val).to.equal('exist');
  });
  it('should be able to revert appended nullifier', async () => {
    let nullifier = soliditySha3(413);
    // Non inclusion proof
    let merkleProof1 = await nullifierTree.merkleProof(nullifier);
    let root1 = await nullifierTree.root();
    expect(merkleProof1.val).to.equal('0');
    // Add leaf
    await nullifierTree.append(nullifier);
    // Inclusion proof
    let merkleProof2 = await nullifierTree.merkleProof(nullifier);
    let root2 = await nullifierTree.root();
    expect(merkleProof2.val).to.equal('exist');
    // Revert
    await nullifierTree.remove(nullifier);
    // Non inclusion proof again
    let merkleProof3 = await nullifierTree.merkleProof(nullifier);
    let root3 = await nullifierTree.root();
    expect(merkleProof3.val).to.equal('0');
    // Compare roots
    // Root3 should be reverted to root1 from root2
    expect(root1).to.equal(root3);
    expect(root1).not.to.equal(root2);
  });
  it('should not affect the tree during its dry run', async () => {
    let nullifiers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16].map(i => soliditySha3(i));
    let root1 = await nullifierTree.root();
    await nullifierTree.dryRunRollUp(nullifiers);
    let root2 = await nullifierTree.root();
    expect(root1).to.equal(root2);
  });
});

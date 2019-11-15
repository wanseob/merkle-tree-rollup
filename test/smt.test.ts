import { SparseMerkleTree } from '../src/sparseMerkleTree';
import { keccak256PreHash } from '../src/keccak256PreHash';
import { soliditySha3 } from 'web3-utils';
import chai from 'chai';
import fs from 'fs-extra';

const expect = chai.expect;

describe('SparseMerkleTree', () => {
  const location = 'testDB2';
  let SMT: SparseMerkleTree;

  before(() => {
    // Initialize the test purpose database directory
    if (fs.existsSync(location)) {
      fs.removeSync(location);
    }
    fs.mkdirSync(location);
    SMT = new SparseMerkleTree(256, location);
  });
  after(() => {
    // Remove the test purpose database
    if (fs.existsSync(location)) {
      fs.removeSync(location);
    }
  });
  it('should return pre hashed value for its initial root', async () => {
    expect(await SMT.root()).to.equal(keccak256PreHash[256]);
  });
  it('should not update the root if 0 added to the leaf', async () => {
    await SMT.updateLeaf(soliditySha3(412), '0');
    expect(await SMT.root()).to.equal(keccak256PreHash[256]);
  });
  it('should update the root when non-zero added to the leaf', async () => {
    await SMT.updateLeaf(soliditySha3(413), '1');
    expect(await SMT.root()).not.to.equal(keccak256PreHash[256]);
  });
  it('should not update the root when same value added to the leaf', async () => {
    let prevRoot = await SMT.root();
    await SMT.updateLeaf(soliditySha3(413), '1');
    let nextRoot = await SMT.root();
    expect(nextRoot).to.equal(prevRoot);
  });
  it('should update the root when different value added to the leaf', async () => {
    let prevRoot = await SMT.root();
    await SMT.updateLeaf(soliditySha3(413), '2');
    let nextRoot = await SMT.root();
    expect(nextRoot).not.to.equal(prevRoot);
  });
  it('should return its proof data', async () => {
    let proof = await SMT.merkleProof(soliditySha3(413));
  });
  it('should verify the proof', async () => {
    let proof = await SMT.merkleProof(soliditySha3(413));
    expect(SMT.verityProof(proof)).to.be.true;
  });
  it('should return false against an invalid proof', async () => {
    let proof = await SMT.merkleProof(soliditySha3(413));
    proof.leaf = soliditySha3(414);
    expect(SMT.verityProof(proof)).to.be.false;
  });
});

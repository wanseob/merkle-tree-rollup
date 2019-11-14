import { SparseMerkleTree } from '../src/index';
import { keccak256PreHash } from '../src/keccak256PreHash';
import chai from 'chai';
import fs from 'fs';
import rimraf from 'rimraf';
import BN from 'bn.js';
import { BADNAME } from 'dns';

const expect = chai.expect;

describe('SparseMerkleTree', () => {
  const location = 'testDB';
  let SMT: SparseMerkleTree;

  before(() => {
    // Initialize the test purpose database directory
    if (fs.existsSync(location)) {
      rimraf.sync(location);
    }
    fs.mkdirSync(location);
    SMT = new SparseMerkleTree(256, location);
  });
  after(() => {
    // Remove the test purpose database
    if (fs.existsSync(location)) {
      rimraf.sync(location);
    }
  });
  it('should return pre hashed value for its root without any insertion', async () => {
    expect(await SMT.root()).to.equal(keccak256PreHash[255]);
  });
  it('should not update the root if 0 added to the leaf', async () => {
    await SMT.updateLeaf(new BN(412), '0');
    expect(await SMT.root()).to.equal(keccak256PreHash[255]);
  });
  it('should update the root when non-zero added to the leaf', async () => {
    await SMT.updateLeaf(new BN(412), '1');
    expect(await SMT.root()).not.to.equal(keccak256PreHash[255]);
  });
  it('should not update the root when same value added to the leaf', async () => {
    let prevRoot = await SMT.root();
    await SMT.updateLeaf(new BN(412), '1');
    let nextRoot = await SMT.root();
    expect(nextRoot).to.equal(prevRoot);
  });
  it('should update the root when different value added to the leaf', async () => {
    let prevRoot = await SMT.root();
    await SMT.updateLeaf(new BN(412), '2');
    let nextRoot = await SMT.root();
    expect(nextRoot).not.to.equal(prevRoot);
  });
  it('should return its proof data', async () => {
    let proof = await SMT.getProof(new BN(412));
  });
  it('should verify the proof', async () => {
    let proof = await SMT.getProof(new BN(412));
    expect(SMT.verityProof(proof)).to.be.true;
  });
  it('should return false against an invalid proof', async () => {
    let proof = await SMT.getProof(new BN(412));
    proof.leaf = new BN(413);
    expect(SMT.verityProof(proof)).to.be.false;
  });
});

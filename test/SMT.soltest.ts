import chai from 'chai';
import { SMT256Instance } from 'truffle-contracts';
import { soliditySha3 } from 'web3-utils';
import fs from 'fs-extra';
import { RollUpSMT } from '../src/rollUpSMT';

const expect = chai.expect;
const SMT256 = artifacts.require('SMT256');

contract('SMT test', async accounts => {
  const location = 'testDB';
  let smtSolLib: SMT256Instance;
  let tree: RollUpSMT;
  before(async () => {
    // Initialize the test purpose database directory
    if (fs.existsSync(location)) {
      fs.removeSync(location);
    }
    fs.mkdirSync(location);
    tree = new RollUpSMT(256, location);
    let nullifiers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map(val => soliditySha3(val));
    await tree.rollUp(nullifiers);
    smtSolLib = await SMT256.deployed();
  });
  after(() => {
    // Remove the test purpose database
    if (fs.existsSync(location)) {
      fs.removeSync(location);
    }
  });
  it('should return true for merkle proof', async () => {
    let merkleProof = await tree.merkleProof(soliditySha3(1));
    let mp = await smtSolLib.merkleProof(
      merkleProof.root.toString(),
      merkleProof.leaf.toString(),
      soliditySha3(merkleProof.val),
      merkleProof.siblings.map(sib => sib.toString())
    );
  });
  it('should return true for its batch roll up proof', async () => {
    let sources = [11, 12];
    let nullifiers = sources.map(val => soliditySha3(val));
    let rollUpResult = await tree.rollUp(nullifiers);
    let proof = rollUpResult.proof;
    await smtSolLib.rollUpProof(
      proof.root.toString(),
      proof.nextRoot.toString(),
      proof.leaves.map(nullifier => nullifier.toString()),
      proof.siblings.map(siblings => siblings.map(sib => sib.toString()))
    );
  });
  it('should return true for its batch roll up proof', async () => {
    let sources = [13, 14, 15, 16];
    let nullifiers = sources.map(val => soliditySha3(val));
    let rollUpResult = await tree.rollUp(nullifiers);
    let proof = rollUpResult.proof;
    await smtSolLib.rollUpProof(
      proof.root.toString(),
      proof.nextRoot.toString(),
      proof.leaves.map(nullifier => nullifier.toString()),
      proof.siblings.map(siblings => siblings.map(sib => sib.toString()))
    );
  });
  it('should return true for its batch roll up proof', async () => {
    let sources = [17, 18, 19, 20, 21, 22, 23, 24];
    let nullifiers = sources.map(val => soliditySha3(val));
    let rollUpResult = await tree.rollUp(nullifiers);
    let proof = rollUpResult.proof;
    await smtSolLib.rollUpProof(
      proof.root.toString(),
      proof.nextRoot.toString(),
      proof.leaves.map(nullifier => nullifier.toString()),
      proof.siblings.map(siblings => siblings.map(sib => sib.toString())),
      {
        gas: 6700000 // Istanbul will reduce the gas cost
      }
    );
  });
});

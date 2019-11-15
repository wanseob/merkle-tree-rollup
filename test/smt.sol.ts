import { SparseMerkleTree } from '../src/sparseMerkleTree';
import chai from 'chai';
import { SMT256Instance } from 'truffle-contracts';
import fs from 'fs-extra';

const expect = chai.expect;
const SMT256 = artifacts.require('SMT256');

contract('SMT test', async accounts => {
  const location = 'testDB';
  let smtSolLib: SMT256Instance;
  let tree: SparseMerkleTree;
  before(async () => {
    // Initialize the test purpose database directory
    if (fs.existsSync(location)) {
      fs.removeSync(location);
    }
    fs.mkdirSync(location);
    tree = new SparseMerkleTree(256, location);
    smtSolLib = await SMT256.deployed();
  });
  it('test1', async () => {});
  after(() => {
    // Remove the test purpose database
    if (fs.existsSync(location)) {
      fs.removeSync(location);
    }
  });
});

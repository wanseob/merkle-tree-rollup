const chai = require('chai');
const { storage, hashers, tree } = require('semaphore-merkle-tree');
const MiMCTree = artifacts.require('MiMCTree');

chai.use(require('chai-bignumber')(web3.utils.BN)).should();

contract('MiMCTree test', async accounts => {
  let rollUpTree;
  let merkleTree;

  beforeEach(async () => {
    rollUpTree = await MiMCTree.deployed();
    merkleTree = new tree.MerkleTree('semaphore', new storage.MemStorage(), new hashers.MimcSpongeHasher(), 31, '0');
  });

  it('push should return the correct merkle root after appending some items', async () => {
    let merkleProof = await merkleTree.path(0);
    let items = [1];
    let prevRoot = await merkleTree.root();
    for (let i = 0; i < items.length; i++) {
      await merkleTree.update(i, items[i]);
    }
    let newRoot = await merkleTree.root();
    await rollUpTree.push(items, merkleProof.path_elements, { gas: 6700000 });
    let updatedTree = await rollUpTree.tree();
    updatedTree.root.toString().should.equal(newRoot.toString());
  });
});

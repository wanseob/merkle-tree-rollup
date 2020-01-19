const chai = require('chai');
const { storage, tree } = require('semaphore-merkle-tree');
const KeccakTree = artifacts.require('KeccakTree');

chai.use(require('chai-bignumber')(web3.utils.BN)).should();

const keccakHasher = {
  hash: (_, left, right) => {
    return web3.utils.toBN(web3.utils.soliditySha3(left, right));
  }
};
contract('Keccak roll up test', async accounts => {
  let rollUpTree;
  let merkleTree;

  beforeEach(async () => {
    rollUpTree = await KeccakTree.new();
    merkleTree = new tree.MerkleTree('semaphore', new storage.MemStorage(), keccakHasher, 31, '0');
  });

  it('push should return the correct merkle root after appending some items', async () => {
    let merkleProof = await merkleTree.path(0);
    let items = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
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

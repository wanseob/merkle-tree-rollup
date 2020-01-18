const chai = require('chai');
const { storage, hashers, tree } = require('semaphore-merkle-tree');
const KeccakRollUp = artifacts.require('KeccakRollUpImpl');

chai.use(require('chai-bignumber')(web3.utils.BN)).should();

const keccakHasher = {
  hash: (_, left, right) => {
    return web3.utils.toBN(web3.utils.soliditySha3(left, right));
  }
};
contract('Keccak roll up test', async accounts => {
  let keccakRollUp;
  let merkleTree;

  beforeEach(async () => {
    keccakRollUp = await KeccakRollUp.new();
    merkleTree = new tree.MerkleTree('semaphore', new storage.MemStorage(), keccakHasher, 31, '0');
  });

  it('The pre hashed zero should be the initial merkle tree root value', async () => {
    let zeroes = await keccakRollUp.preHashedZero();
    let initialRoot = await merkleTree.root();
    initialRoot.should.equal(zeroes[31].toString());
  });

  it('parentOf zero hashes should return the same result with the PreHashedZero values', async () => {
    let zeroes = await keccakRollUp.preHashedZero();
    for (let i = 1; i < 32; i++) {
      let parentZero = await keccakRollUp.parentOf(zeroes[i - 1], zeroes[i - 1]);
      parentZero.toString().should.equal(zeroes[i].toString());
    }
  });

  it('The pre hashed zero should be the initial merkle tree root value', async () => {
    let zeroes = await keccakRollUp.preHashedZero();
    let initialRootMerkleProof = await keccakRollUp.merkleProof(zeroes[31], zeroes[0], 0, zeroes.slice(0, 31));
    initialRootMerkleProof.should.equal(true);
  });

  it('should return true for the merkle proof', async () => {
    let index = 0;
    let items = [1111, 2222, 3333];
    for (let i = 0; i < items.length; i++) {
      await merkleTree.update(index, items[i]);
      index += 1;
    }
    let targetIndex = 0;
    let merkleProof = await merkleTree.path(targetIndex);
    let proof = await keccakRollUp.merkleProof(merkleProof.root, merkleProof.element, targetIndex, merkleProof.path_elements);
    proof.should.equal(true);
  });

  it('Roll up and merkle tree js lib should have same value after inserting same items', async () => {
    let merkleProof = await merkleTree.path(0);
    let items = [1, 2, 3];
    let prevRoot = await merkleTree.root();
    let rolledUpRoot = await keccakRollUp.rollUp(prevRoot, 0, items, merkleProof.path_elements, { gas: 6700000 });
    for (let i = 0; i < items.length; i++) {
      await merkleTree.update(i, items[i]);
    }
    let newRoot = await merkleTree.root();
    newRoot.toString().should.equal(rolledUpRoot.toString());
  });

  it('push should return the correct merkle root after appending some items', async () => {
    let merkleProof = await merkleTree.path(0);
    let items = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    let prevRoot = await merkleTree.root();
    for (let i = 0; i < items.length; i++) {
      await merkleTree.update(i, items[i]);
    }
    let newRoot = await merkleTree.root();
    await keccakRollUp.push(items, merkleProof.path_elements, { gas: 6700000 });
    let updatedTree = await keccakRollUp.tree();
    updatedTree.root.toString().should.equal(newRoot.toString());
  });
});

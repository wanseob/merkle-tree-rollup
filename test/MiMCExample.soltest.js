const chai = require('chai');
const { storage, hashers, tree } = require('semaphore-merkle-tree');
const MiMCRollUp = artifacts.require('MiMCExample');

chai.use(require('chai-bignumber')(web3.utils.BN)).should();

contract('MiMC Example Test', async accounts => {
  let rollUpTree;
  let merkleTree;

  beforeEach(async () => {
    rollUpTree = await MiMCRollUp.deployed();
    merkleTree = new tree.MerkleTree('semaphore', new storage.MemStorage(), new hashers.MimcSpongeHasher(), 31, '0');
  });

  it('The pre hashed zero should be the initial merkle tree root value', async () => {
    let zeroes = await rollUpTree.preHashedZero();
    let initialRoot = await merkleTree.root();
    initialRoot.should.equal(zeroes[31].toString());
  });

  it('parentOf zero hashes should return the same result with the PreHashedZero values', async () => {
    let zeroes = await rollUpTree.preHashedZero();
    for (let i = 1; i < 32; i++) {
      let parentZero = await rollUpTree.parentOf(zeroes[i - 1], zeroes[i - 1]);
      parentZero.toString().should.equal(zeroes[i].toString());
    }
  });

  it('The pre hashed zero should be the initial merkle tree root value', async () => {
    let zeroes = await rollUpTree.preHashedZero();
    let initialRootMerkleProof = await rollUpTree.merkleProof(zeroes[31], zeroes[0], 0, zeroes.slice(0, 31));
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
    let proof = await rollUpTree.merkleProof(merkleProof.root, merkleProof.element, targetIndex, merkleProof.path_elements);
    proof.should.equal(true);
  });

  it('Roll up and merkle tree js lib should have same value after inserting same items', async () => {
    let merkleProof = await merkleTree.path(0);
    let items = [1, 2, 3];
    let prevRoot = await merkleTree.root();
    let rolledUpRoot = await rollUpTree.rollUp(prevRoot, 0, items, merkleProof.path_elements, { gas: 6700000 });
    for (let i = 0; i < items.length; i++) {
      await merkleTree.update(i, items[i]);
    }
    let newRoot = await merkleTree.root();
    newRoot.should.equal(rolledUpRoot.toString());
  });
});

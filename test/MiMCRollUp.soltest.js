const chai = require('chai');
const { storage, hashers, tree } = require('semaphore-merkle-tree');
const MiMCRollUp = artifacts.require('MiMCRollUp');

chai.use(require('chai-bignumber')(web3.utils.BN)).should();

contract('MiMC roll up test', async accounts => {
  let mimcRollUp;
  let merkleTree;

  beforeEach(async () => {
    mimcRollUp = await MiMCRollUp.deployed();
    merkleTree = new tree.MerkleTree('semaphore', new storage.MemStorage(), new hashers.MimcSpongeHasher(), 31, '0');
  });

  it('The pre hashed zero should be the initial merkle tree root value', async () => {
    let zeroes = await mimcRollUp.preHashedZero();
    let initialRoot = await merkleTree.root();
    initialRoot.should.equal(zeroes[31].toString());
  });

  it('parentOf zero hashes should return the same result with the PreHashedZero values', async () => {
    let zeroes = await mimcRollUp.preHashedZero();
    for (let i = 1; i < 32; i++) {
      let parentZero = await mimcRollUp.parentOf(zeroes[i - 1], zeroes[i - 1]);
      parentZero.toString().should.equal(zeroes[i].toString());
    }
  });

  it('The pre hashed zero should be the initial merkle tree root value', async () => {
    let zeroes = await mimcRollUp.preHashedZero();
    let initialRootMerkleProof = await mimcRollUp.merkleProof(zeroes[31], zeroes[0], 0, zeroes.slice(0, 31));
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
    let proof = await mimcRollUp.merkleProof(merkleProof.root, merkleProof.element, targetIndex, merkleProof.path_elements);
    proof.should.equal(true);
  });

  it('Roll up and merkle tree js lib should have same value after inserting same items', async () => {
    let merkleProof = await merkleTree.path(0);
    let items = [1, 2, 3];
    let prevRoot = await merkleTree.root();
    let rolledUpRoot = await mimcRollUp.rollUp(prevRoot, 0, items, merkleProof.path_elements, { gas: 6700000 });
    for (let i = 0; i < items.length; i++) {
      await merkleTree.update(i, items[i]);
    }
    let newRoot = await merkleTree.root();
    newRoot.should.equal(rolledUpRoot.toString());
  });
});

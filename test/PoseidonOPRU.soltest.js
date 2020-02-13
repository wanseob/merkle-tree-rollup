const chai = require('chai');
const expect = chai.expect;
chai.use(require('chai-as-promised'));
chai.use(require('chai-bn')(web3.utils.BN));

const { storage, hashers, tree } = require('semaphore-merkle-tree');
const { poseidon } = require('circomlib');

const PoseidonOPRU = artifacts.require('PoseidonOPRU');

chai.use(require('chai-bignumber')(web3.utils.BN)).should();

const poseidonHash = poseidon.createHash(6, 8, 57);
const PoseidonHasher = {
  hash: (_, left, right) => {
    return poseidonHash([left, right]).toString();
  }
};

contract('Poseidon OPRU Test', async accounts => {
  let poseidonOPRU;
  let merkleTree;
  let validRollUp = {};
  let invalidRollUp = {};
  let index = 0;

  before(async () => {
    poseidonOPRU = await PoseidonOPRU.deployed();
    merkleTree = new tree.MerkleTree('poseidon', new storage.MemStorage(), PoseidonHasher, 31, '0');
    /** Create valid roll up */
    validRollUp.startingRoot = await merkleTree.root();
    validRollUp.initialSiblings = (await merkleTree.path(index)).path_elements;
    validRollUp.startingIndex = index;
    let items = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    validRollUp.leaves = items;
    for (let i = 0; i < items.length; i++) {
      await merkleTree.update(index, items[i]);
      index += 1;
    }
    validRollUp.targetingRoot = await merkleTree.root();

    /** Create invalid roll up */
    invalidRollUp.startingRoot = await merkleTree.root();
    invalidRollUp.initialSiblings = (await merkleTree.path(index)).path_elements;
    invalidRollUp.startingIndex = index;
    items = [11, 12, 13, 14, 15, 16, 17, 18, 19, 20];
    // Omit the last item intentionally
    invalidRollUp.leaves = items.slice(0, items.length - 1);
    for (let i = 0; i < items.length; i++) {
      await merkleTree.update(index, items[i]);
      index += 1;
    }
    invalidRollUp.targetingRoot = await merkleTree.root();
  });

  describe('Valid optimistic roll up', async () => {
    let proposalId;
    let challengeDue;
    it('should emit an event when new optimistic roll up is submitted', async () => {
      let proposal = await poseidonOPRU.propose(validRollUp.startingRoot, validRollUp.startingIndex, validRollUp.leaves, validRollUp.targetingRoot);
      proposalId = proposal.logs[0].args.id;
      proposalId.should.be.a.bignumber.that.is.zero;
      challengeDue = (await poseidonOPRU.getProposal(proposalId)).challengeDue.toNumber();
    });
    it('should reject the finalization request until its challenge period', async () => {
      await expect(poseidonOPRU.finalize(proposalId)).to.be.rejected;
    });
    it.skip('should fulfill the finalization after its challenge period', async () => {
      while (parseInt(new Date().getTime() / 1000) <= challengeDue);
      await expect(poseidonOPRU.finalize(proposalId)).to.be.fulfilled;
    });
  });
  describe('Invalid OPRU will get reverted by the challenge', async () => {
    describe('How challenge roll up works', async () => {
      let rollUpId;
      it('should emit an event when it starts a new storage based roll up', async () => {
        let rollUp = await poseidonOPRU.newSplitRollUp(validRollUp.startingRoot, validRollUp.startingIndex, validRollUp.initialSiblings);
        rollUpId = rollUp.logs[0].args.id;
        rollUpId.should.be.a.bignumber.that.is.zero;
      });
      it('should be able to append all items with multiple transactions', async () => {
        await poseidonOPRU.updateSplitRollUp(rollUpId, validRollUp.leaves.slice(0, 2));
        await poseidonOPRU.updateSplitRollUp(rollUpId, validRollUp.leaves.slice(2, 4));
        await poseidonOPRU.updateSplitRollUp(rollUpId, validRollUp.leaves.slice(4, 6));
        await poseidonOPRU.updateSplitRollUp(rollUpId, validRollUp.leaves.slice(6, 8));
        await poseidonOPRU.updateSplitRollUp(rollUpId, validRollUp.leaves.slice(8, 10));
      });
    });
    describe('Challenge', async () => {
      let proposalId;
      let rollUpId;
      it('should create a new optimistic roll up', async () => {
        let proposal = await poseidonOPRU.propose(invalidRollUp.startingRoot, invalidRollUp.startingIndex, invalidRollUp.leaves, invalidRollUp.targetingRoot);
        proposalId = proposal.logs[0].args.id;
        let rollUp = await poseidonOPRU.newSplitRollUp(invalidRollUp.startingRoot, invalidRollUp.startingIndex, invalidRollUp.initialSiblings);
        rollUpId = rollUp.logs[0].args.id;
      });
      it('should be able to append all items with multiple transactions', async () => {
        await poseidonOPRU.updateSplitRollUp(rollUpId, invalidRollUp.leaves.slice(0, 2));
        await poseidonOPRU.updateSplitRollUp(rollUpId, invalidRollUp.leaves.slice(2, 4));
        await poseidonOPRU.updateSplitRollUp(rollUpId, invalidRollUp.leaves.slice(4, 6));
        await poseidonOPRU.updateSplitRollUp(rollUpId, invalidRollUp.leaves.slice(6, 8));
        await poseidonOPRU.updateSplitRollUp(rollUpId, invalidRollUp.leaves.slice(8, 10));
      });
      it('should emit a Slashed event for the challenge', async () => {
        let receipt = await poseidonOPRU.challenge(proposalId, rollUpId);
        receipt.logs[0].args.proposalId.eq(proposalId).should.equal(true);
      });
    });
  });
});

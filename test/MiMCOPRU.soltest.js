const chai = require('chai');
const expect = chai.expect;
chai.use(require('chai-as-promised'));
chai.use(require('chai-bn')(web3.utils.BN));

const { storage, hashers, tree } = require('semaphore-merkle-tree');
const MiMCOPRU = artifacts.require('MiMCOPRU');

chai.use(require('chai-bignumber')(web3.utils.BN)).should();

contract.only('MiMC OPRU Test', async accounts => {
  let mimcOPRU;
  let merkleTree;
  let validRollUp = {};
  let invalidRollUp = {};
  let index = 0;

  before(async () => {
    mimcOPRU = await MiMCOPRU.deployed();
    merkleTree = new tree.MerkleTree('semaphore', new storage.MemStorage(), new hashers.MimcSpongeHasher(), 31, '0');
    /** Create valid roll up */
    validRollUp.startingRoot = await merkleTree.root();
    validRollUp.initialSiblings = (await merkleTree.path(index)).path_elements;
    validRollUp.startingIndex = index;
    let items = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    validRollUp.leaves = items;
    for (let i = 0; i < items.length; i++) {
      await merkleTree.update(i, items[i]);
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
      await merkleTree.update(i, items[i]);
      index += 1;
    }
    invalidRollUp.targetingRoot = await merkleTree.root();
  });

  describe('Valid optimistic roll up', async () => {
    let proposalId;
    let challengeDue;
    it('should emit an event when new optimistic roll up is submitted', async () => {
      let proposal = await mimcOPRU.propose(validRollUp.startingRoot, validRollUp.startingIndex, validRollUp.leaves, validRollUp.targetingRoot);
      proposalId = proposal.logs[0].args.id;
      proposalId.should.be.a.bignumber.that.is.zero;
      challengeDue = (await mimcOPRU.getProposal(proposalId)).challengeDue.toNumber();
    });
    it('should reject the finalization request until its challenge period', async () => {
      await expect(mimcOPRU.finalize(proposalId)).to.be.rejected;
    });
    it('should fulfill the finalization after its challenge period', async () => {
      while (parseInt(new Date().getTime() / 1000) <= challengeDue);
      await expect(mimcOPRU.finalize(proposalId)).to.be.fulfilled;
    });
  });
  describe('Invalid OPRU will get reverted by the challenge', async () => {
    describe('How challenge roll up works', async () => {
      let rollUpId;
      it('should emit an event when it starts a new storage based roll up', async () => {
        let rollUp = await mimcOPRU.newSplitRollUp(validRollUp.startingRoot, validRollUp.startingIndex, validRollUp.initialSiblings);
        rollUpId = rollUp.logs[0].args.id;
        rollUpId.should.be.a.bignumber.that.is.zero;
      });
      it('should be able to append all items with multiple transactions', async () => {
        await mimcOPRU.updateSplitRollUp(rollUpId, validRollUp.leaves.slice(0, 3));
        await mimcOPRU.updateSplitRollUp(rollUpId, validRollUp.leaves.slice(3, 6));
        await mimcOPRU.updateSplitRollUp(rollUpId, validRollUp.leaves.slice(6, 9));
        await mimcOPRU.updateSplitRollUp(rollUpId, validRollUp.leaves.slice(9, 10));
      });
    });
    describe('Challenge', async () => {
      let proposalId;
      let rollUpId;
      it('should create a new optimistic roll up', async () => {
        let proposal = await mimcOPRU.propose(invalidRollUp.startingRoot, invalidRollUp.startingIndex, invalidRollUp.leaves, invalidRollUp.targetingRoot);
        proposalId = proposal.logs[0].args.id;
        let rollUp = await mimcOPRU.newSplitRollUp(invalidRollUp.startingRoot, invalidRollUp.startingIndex, invalidRollUp.initialSiblings);
        rollUpId = rollUp.logs[0].args.id;
      });
      it('should be able to append all items with multiple transactions', async () => {
        await mimcOPRU.updateSplitRollUp(rollUpId, invalidRollUp.leaves.slice(0, 3));
        await mimcOPRU.updateSplitRollUp(rollUpId, invalidRollUp.leaves.slice(3, 6));
        await mimcOPRU.updateSplitRollUp(rollUpId, invalidRollUp.leaves.slice(6, 9));
        await mimcOPRU.updateSplitRollUp(rollUpId, invalidRollUp.leaves.slice(9, 10));
      });
      it('should emit a Slashed event for the challenge', async () => {
        let receipt = await mimcOPRU.challenge(proposalId, rollUpId);
        receipt.logs[0].args.proposalId.eq(proposalId).should.equal(true);
      });
    });
  });
});

const chai = require('chai');
const expect = chai.expect;
chai.use(require('chai-as-promised'));
chai.use(require('chai-bn')(web3.utils.BN));

const { storage, hashers, tree } = require('semaphore-merkle-tree');
const { poseidon } = require('circomlib');

const PoseidonSubTreeRollUp = artifacts.require('PoseidonSubTreeRollUp');

chai.use(require('chai-bignumber')(web3.utils.BN)).should();

const poseidonHash = poseidon.createHash(6, 8, 57);
const PoseidonHasher = {
  hash: (_, left, right) => {
    return poseidonHash([left, right]).toString();
  }
};

contract('Poseidon Subtree Roll Up Test', async accounts => {
  let poseidonSubTreeRollUp;
  let merkleTree;
  let validRollUp = {};
  let invalidRollUp = {};
  let index = 0;
  const SUB_TREE_DEPTH = 5;
  const SUB_TREE_SIZE = 1 << SUB_TREE_DEPTH;

  before(async () => {
    poseidonSubTreeRollUp = await PoseidonSubTreeRollUp.deployed();
    merkleTree = new tree.MerkleTree('poseidon', new storage.MemStorage(), PoseidonHasher, 31, '0');
    /** Create valid roll up */
    validRollUp.startingRoot = await merkleTree.root();
    validRollUp.initialSiblings = (await merkleTree.path(index)).path_elements.slice(SUB_TREE_DEPTH);
    validRollUp.startingIndex = index;
    let items = [...Array(189).keys()];
    validRollUp.leaves = items;
    for (let i = 0; i < items.length; i++) {
      await merkleTree.update(index + i, items[i]);
    }
    index += Math.ceil(items.length / SUB_TREE_SIZE) * SUB_TREE_SIZE;
    validRollUp.targetingRoot = await merkleTree.root();

    /** Create invalid roll up */
    invalidRollUp.startingRoot = await merkleTree.root();
    invalidRollUp.initialSiblings = (await merkleTree.path(index)).path_elements.slice(SUB_TREE_DEPTH);
    invalidRollUp.startingIndex = index;
    // Omit the last item intentionally
    invalidRollUp.leaves = items.slice(0, items.length - 1);
    for (let i = 0; i < items.length; i++) {
      await merkleTree.update(index + i, items[i]);
    }
    index += Math.ceil(items.length / SUB_TREE_SIZE) * SUB_TREE_SIZE;
    invalidRollUp.targetingRoot = await merkleTree.root();
  });

  describe('Valid optimistic roll up', async () => {
    let proposalId;
    let challengeDue;
    it('should emit an event when new optimistic roll up is submitted', async () => {
      let proposal = await poseidonSubTreeRollUp.propose(validRollUp.startingRoot, validRollUp.startingIndex, validRollUp.leaves, validRollUp.targetingRoot);
      proposalId = proposal.logs[0].args.id;
      proposalId.should.be.a.bignumber.that.is.zero;
      challengeDue = (await poseidonSubTreeRollUp.getProposal(proposalId)).challengeDue.toNumber();
    });
    it('should reject the finalization request until its challenge period', async () => {
      await expect(poseidonSubTreeRollUp.finalize(proposalId)).to.be.rejected;
    });
    it.skip('should fulfill the finalization after its challenge period', async () => {
      while (parseInt(new Date().getTime() / 1000) <= challengeDue);
      await expect(poseidonSubTreeRollUp.finalize(proposalId)).to.be.fulfilled;
    });
  });
  describe('Invalid OPRU will get reverted by the challenge', async () => {
    describe('How challenge roll up works', async () => {
      let rollUpId;
      it('should emit an event when it starts a new storage based roll up', async () => {
        let rollUp = await poseidonSubTreeRollUp.newSplitRollUp(validRollUp.startingRoot, validRollUp.startingIndex, validRollUp.initialSiblings);
        rollUpId = rollUp.logs[0].args.id;
        rollUpId.should.be.a.bignumber.that.is.zero;
      });
      it('should be able to append all items with multiple transactions', async () => {
        await poseidonSubTreeRollUp.updateSplitRollUp(rollUpId, validRollUp.leaves.slice(0, 32));
        await poseidonSubTreeRollUp.updateSplitRollUp(rollUpId, validRollUp.leaves.slice(32, 64));
        await poseidonSubTreeRollUp.updateSplitRollUp(rollUpId, validRollUp.leaves.slice(64, 96));
        await poseidonSubTreeRollUp.updateSplitRollUp(rollUpId, validRollUp.leaves.slice(96, 128));
        await poseidonSubTreeRollUp.updateSplitRollUp(rollUpId, validRollUp.leaves.slice(128, 160));
        await poseidonSubTreeRollUp.updateSplitRollUp(rollUpId, validRollUp.leaves.slice(160));
      });
    });
    describe('Challenge', async () => {
      let proposalId;
      let rollUpId;
      it('should create a new optimistic roll up', async () => {
        let proposal = await poseidonSubTreeRollUp.propose(
          invalidRollUp.startingRoot,
          invalidRollUp.startingIndex,
          invalidRollUp.leaves,
          invalidRollUp.targetingRoot
        );
        proposalId = proposal.logs[0].args.id;
        let rollUp = await poseidonSubTreeRollUp.newSplitRollUp(invalidRollUp.startingRoot, invalidRollUp.startingIndex, invalidRollUp.initialSiblings);
        rollUpId = rollUp.logs[0].args.id;
      });
      it('should be able to append all items with multiple transactions', async () => {
        await poseidonSubTreeRollUp.updateSplitRollUp(rollUpId, invalidRollUp.leaves.slice(0, 32));
        await poseidonSubTreeRollUp.updateSplitRollUp(rollUpId, invalidRollUp.leaves.slice(32, 64));
        await poseidonSubTreeRollUp.updateSplitRollUp(rollUpId, invalidRollUp.leaves.slice(64, 96));
        await poseidonSubTreeRollUp.updateSplitRollUp(rollUpId, invalidRollUp.leaves.slice(96, 128));
        await poseidonSubTreeRollUp.updateSplitRollUp(rollUpId, invalidRollUp.leaves.slice(128, 160));
        await poseidonSubTreeRollUp.updateSplitRollUp(rollUpId, invalidRollUp.leaves.slice(160));
      });
      it('should emit a Slashed event for the challenge', async () => {
        let receipt = await poseidonSubTreeRollUp.challenge(proposalId, rollUpId);
        receipt.logs[0].args.proposalId.eq(proposalId).should.equal(true);
      });
    });
  });
});

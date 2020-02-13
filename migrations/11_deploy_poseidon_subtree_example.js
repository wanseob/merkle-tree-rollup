const Poseidon = artifacts.require('Poseidon');
const PoseidonSubTreeRollUp = artifacts.require('PoseidonSubTreeRollUp');

module.exports = function(deployer) {
  deployer.link(Poseidon, PoseidonSubTreeRollUp);
  deployer.deploy(PoseidonSubTreeRollUp);
};

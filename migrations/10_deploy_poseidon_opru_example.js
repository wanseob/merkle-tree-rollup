const Poseidon = artifacts.require('Poseidon');
const PoseidonOPRU = artifacts.require('PoseidonOPRU');

module.exports = function(deployer) {
  deployer.link(Poseidon, PoseidonOPRU);
  deployer.deploy(PoseidonOPRU);
};

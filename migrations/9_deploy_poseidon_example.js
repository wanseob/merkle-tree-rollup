const Poseidon = artifacts.require('Poseidon');
const PoseidonExample = artifacts.require('PoseidonExample');

module.exports = function(deployer) {
  deployer.link(Poseidon, PoseidonExample);
  deployer.deploy(PoseidonExample);
};

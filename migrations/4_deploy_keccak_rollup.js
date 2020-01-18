const KeccakRollUp = artifacts.require('KeccakRollUpImpl');

module.exports = function(deployer) {
  deployer.deploy(KeccakRollUp);
};

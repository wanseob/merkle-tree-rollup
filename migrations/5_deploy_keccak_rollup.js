const KeccakRollUp = artifacts.require('KeccakRollUp');

module.exports = function(deployer) {
  deployer.deploy(KeccakRollUp);
};

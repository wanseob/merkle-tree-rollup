const KeccakRollUp = artifacts.require('KeccakRollUpExample');

module.exports = function(deployer) {
  deployer.deploy(KeccakRollUp);
};

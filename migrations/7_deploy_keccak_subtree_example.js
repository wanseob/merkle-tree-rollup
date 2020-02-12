const KeccakSubTreeRollUp = artifacts.require('KeccakSubTreeRollUp');

module.exports = function(deployer) {
  deployer.deploy(KeccakSubTreeRollUp);
};

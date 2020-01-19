const KeccakTree = artifacts.require('KeccakTree');

module.exports = function(deployer) {
  deployer.deploy(KeccakTree);
};

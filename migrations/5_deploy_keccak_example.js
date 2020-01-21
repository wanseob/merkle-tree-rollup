const KeccakExample = artifacts.require('KeccakExample');

module.exports = function(deployer) {
  deployer.deploy(KeccakExample);
};

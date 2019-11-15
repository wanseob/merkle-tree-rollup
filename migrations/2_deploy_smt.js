const SMT256 = artifacts.require('SMT256');

module.exports = function(deployer) {
  deployer.deploy(SMT256);
};

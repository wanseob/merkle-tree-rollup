const MiMC = artifacts.require('MiMC');
const MiMCRollUp = artifacts.require('MiMCRollUpImpl');

module.exports = function(deployer) {
  deployer.link(MiMC, MiMCRollUp);
  deployer.deploy(MiMCRollUp);
};

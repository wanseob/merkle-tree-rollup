const MiMC = artifacts.require('MiMC');
const MiMCRollUp = artifacts.require('MiMCRollUp');

module.exports = function(deployer) {
  deployer.link(MiMC, MiMCRollUp);
  deployer.deploy(MiMCRollUp);
};

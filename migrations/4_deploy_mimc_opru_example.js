const MiMC = artifacts.require('MiMC');
const MiMCOPRU = artifacts.require('MiMCOPRU');

module.exports = function(deployer) {
  deployer.link(MiMC, MiMCOPRU);
  deployer.deploy(MiMCOPRU);
};

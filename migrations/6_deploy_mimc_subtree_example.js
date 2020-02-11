const MiMC = artifacts.require('MiMC');
const MiMCSubTreeRollUp = artifacts.require('MiMCSubTreeRollUp');

module.exports = function(deployer) {
  deployer.link(MiMC, MiMCSubTreeRollUp);
  deployer.deploy(MiMCSubTreeRollUp);
};

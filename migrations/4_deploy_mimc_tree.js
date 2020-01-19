const MiMC = artifacts.require('MiMC');
const MiMCTree = artifacts.require('MiMCTree');

module.exports = function(deployer) {
  deployer.link(MiMC, MiMCTree);
  deployer.deploy(MiMCTree);
};

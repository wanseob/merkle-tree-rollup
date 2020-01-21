const MiMC = artifacts.require('MiMC');
const MiMCExample = artifacts.require('MiMCExample');

module.exports = function(deployer) {
  deployer.link(MiMC, MiMCExample);
  deployer.deploy(MiMCExample);
};

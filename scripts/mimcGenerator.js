console.log('> Compiling MiMC library');
const path = require('path');
const fs = require('fs');

const mimcGenContract = require('circomlib/src/mimcsponge_gencontract.js');
const Artifactor = require('truffle-artifactor');
const SEED = 'mimcsponge';

const contractsDir = path.join(__dirname, '..', 'build/generated');
let artifactor = new Artifactor(contractsDir);
let mimcContractName = 'MiMC';
fs.mkdirSync(contractsDir, { recursive: true });
(async () => {
  await artifactor.save({
    contractName: mimcContractName,
    abi: mimcGenContract.abi,
    unlinked_binary: mimcGenContract.createCode(SEED, 220)
  });
})();

# smt-rollup

- It manages the Sparse Merkle Tree using rocksdb in local environment
- The solidity library provides function to verify that the new root is valid when if the given leaves are added to the previous root.

## Usage

### Solidity library

#### In Remix

```solidity
import { SMT256 } from "github.com/wilsonbeam/smt-rollup/contracts/SMT.sol"
```

#### In Truffle

Install the package first

```shell
npm install --save smt-rollup
```

And use the library

```solidity
import { SMT256 } from "wilsonbeam/smt-rollup/contracts/SMT.sol"
```

### JS library for SMT management

```
let location = "your-db-location"
let nullifierTree = new NullifierTree(256, location); // Use 256 depth tree for the integrition with Solidity library
```

## Future works

- [ ] DB interface for remote databases

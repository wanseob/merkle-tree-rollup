# smt-rollup

- It manages the Sparse Merkle Tree using rocksdb in local environment
- The solidity library provides function to verify that the new root is valid when if the given leaves are added to the previous root.

## Example

- [roll up contract](./example/RollUp.sol)
- [optimistic roll up contract](./example/OptimisticRollUp.sol)
- [Local Sparse Merkle Tree Manager](./example/rollUp.ts)

## Future works

- [ ] DB interface for remote databases

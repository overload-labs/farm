# Overload Farm

The initial rollout farming contract for `Overload`.

It's a minimal wrapper for `ERC-20` tokens, where token addresses are converted into `uint256` and accounted for by `ERC-6909`.

The function added to the `Farm.sol` contract are `deposit` and `withdraw`, rest are tested functions from Uniswap's `ERC-6909` contract, with `transfer` and `transferFrom` disabled (users are supposed to use the deposit and withdraw functions).

The `Router.sol` is a periphery contract and can be updated and re-deployed, if needed. Migration to the full immutable `Overload.sol` contract will include a migration contract.

## Test

```sh
forge test
```

## Contracts

```ml
src
├─ interfaces
│  ├─ IERC20.sol
│  └─ IWETH9.sol
├─ libraries
│  ├─ Lock.sol
│  ├─ Payment.sol
│  ├─ TokenId.sol
│  └─ TransferHelper.sol
├─ token
│  └─ ERC6909.sol
├─ Farm.sol
└─ Router.sol
```

# MultiClaim

A helper contract for claiming multiple non-consecutive loans in a single transaction.

**Source:** `contracts/MultiClaim.sol`

## Overview

The BasePool's `claim()` function requires loan indices to be ascending within a single call. MultiClaim allows LPs to claim multiple groups of loans efficiently.

## Use Case

Consider an LP with shares in loans 1-5 and 10-15, but not 6-9:

**Without MultiClaim:**
```javascript
// Two separate transactions
await pool.claim(lp, [1, 2, 3, 4, 5], false, deadline);
await pool.claim(lp, [10, 11, 12, 13, 14, 15], false, deadline);
```

**With MultiClaim:**
```javascript
// Single transaction
await multiClaim.claimMultiple(
    poolAddress,
    [[1, 2, 3, 4, 5], [10, 11, 12, 13, 14, 15]],
    [false, false],
    deadline
);
```

## Functions

### claimMultiple

```solidity
function claimMultiple(
    IBasePool _pool,
    uint256[][] calldata _loanIdxs,
    bool[] calldata _isReinvested,
    uint256 _deadline
) external
```

Claims from multiple groups of loans in a single transaction.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `_pool` | `IBasePool` | Pool to claim from |
| `_loanIdxs` | `uint256[][]` | Array of arrays of loan indices |
| `_isReinvested` | `bool[]` | Whether to reinvest each group |
| `_deadline` | `uint256` | Transaction deadline |

**Requirements:**
- `_loanIdxs.length > 0`
- `_loanIdxs.length == _isReinvested.length`
- Each sub-array must be non-empty
- Each sub-array must have ascending loan indices

**Example:**

```javascript
const multiClaim = new ethers.Contract(multiClaimAddress, MultiClaimABI, signer);

// Claim loans 1-5 (reinvest) and 10-15 (withdraw)
await multiClaim.claimMultiple(
    poolAddress,
    [
        [1, 2, 3, 4, 5],      // First group
        [10, 11, 12, 13, 14, 15] // Second group
    ],
    [true, false],           // Reinvest first, withdraw second
    Math.floor(Date.now() / 1000) + 3600
);
```

## How It Works

1. Fetches loan and collateral token addresses from pool
2. Records token balances before claiming
3. Iterates through each sub-array, calling `pool.claim()`
4. Calculates tokens received
5. Transfers any non-reinvested tokens to caller

```
┌─────────────────────────────────────────────────────────────────┐
│                     MultiClaim Contract                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Get pool info (tokens)                                      │
│     ┌─────────────┐                                             │
│     │   Pool      │ ──► loanCcyToken, collCcyToken             │
│     └─────────────┘                                             │
│                                                                 │
│  2. Record balances before                                      │
│     balanceBefore[loanCcy] = balance                            │
│     balanceBefore[collCcy] = balance                            │
│                                                                 │
│  3. Process each claim group                                    │
│     for each (loanIdxs, isReinvested):                          │
│         pool.claim(caller, loanIdxs, isReinvested, deadline)    │
│                                                                 │
│  4. Transfer received tokens to caller                          │
│     if loanCcy balance increased: transfer to caller            │
│     if collCcy balance increased: transfer to caller            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Setup Requirements

Before using MultiClaim, you must approve it to act on your behalf in the pool:

```javascript
// Approve MultiClaim for CLAIM permission (bit 3 = 8)
await pool.setApprovals(multiClaimAddress, 8);

// If reinvesting, also need ADD_LIQUIDITY (bit 1 = 2)
// CLAIM + ADD_LIQUIDITY = 8 + 2 = 10
await pool.setApprovals(multiClaimAddress, 10);
```

## Gas Considerations

MultiClaim saves gas when claiming non-consecutive loans:

| Scenario | Without MultiClaim | With MultiClaim |
|----------|-------------------|-----------------|
| 2 groups | 2 transactions | 1 transaction |
| 3 groups | 3 transactions | 1 transaction |
| 5 groups | 5 transactions | 1 transaction |

Savings increase with:
- More claim groups
- Higher base gas cost per transaction
- Network congestion

## Error Messages

| Error | Meaning |
|-------|---------|
| `MultiClaim: Empty loan index array.` | `_loanIdxs` is empty |
| `MultiClaim: Inconsistent lengths.` | Arrays have different lengths |
| `MultiClaim: Empty loan index sub-array.` | A sub-array is empty |

## Related

- [BasePool Reference](base-pool.md)
- [Claiming Rewards Guide](../../guides/claiming.md)

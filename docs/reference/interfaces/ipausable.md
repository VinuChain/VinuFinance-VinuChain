# IPausable Interface

Interface for pausable pool contracts.

**Source:** `contracts/interfaces/IPausable.sol`

## Overview

The IPausable interface defines the pause/unpause functionality that allows the Controller to halt pool operations during emergencies.

## Functions

### pause

```solidity
function pause() external;
```

Pauses the contract, preventing borrowing operations.

**Access:** Only callable by the Controller contract.

**Effects:**
- Sets paused state to true
- `borrow()` function will revert while paused
- Other functions (addLiquidity, removeLiquidity, repay, claim) remain operational

### unpause

```solidity
function unpause() external;
```

Unpauses the contract, resuming normal operations.

**Access:** Only callable by the Controller contract.

## Usage in BasePool

```solidity
contract BasePool is IBasePool, Pausable, IPausable {

    function borrow(...) external payable whenNotPaused {
        // Only works when not paused
    }

    function pause() external override {
        require(msg.sender == address(poolController), "Not the controller.");
        _pause();
    }

    function unpause() external override {
        require(msg.sender == address(poolController), "Not the controller.");
        _unpause();
    }
}
```

## When Paused

| Function | Available? |
|----------|------------|
| `addLiquidity()` | Yes |
| `removeLiquidity()` | Yes |
| `borrow()` | **No** |
| `repay()` | Yes |
| `claim()` | Yes |

## Governance Flow

```
┌────────────────────────────────────────────────────────────────┐
│                    Pause Flow                                   │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  1. User creates PAUSE proposal                                │
│     controller.createProposal(pool, PAUSE, deadline)           │
│                                                                │
│  2. Token holders vote                                         │
│     controller.vote(proposalIdx)                               │
│                                                                │
│  3. If threshold reached, proposal executes                    │
│     proposals[idx].target.pause() ──► pool._pause()           │
│                                                                │
│  4. Pool is now paused                                         │
│     borrow() reverts with "Pausable: paused"                   │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

## Related

- [Controller Reference](../contracts/controller.md)
- [BasePool Reference](../contracts/base-pool.md)
- [Governance Guide](../../guides/governance.md)

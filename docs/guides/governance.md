# Governance

This guide explains how to participate in VinuFinance protocol governance through the Controller contract.

## Overview

VinuFinance governance allows token holders to:

1. **Vote on proposals** - Pause/unpause pools, whitelist/dewhitelist for rewards
2. **Earn protocol revenue** - Share of fees from all pools
3. **Stake governance tokens** - Deposit tokens to gain voting power

## Governance Actions

| Action | Effect |
|--------|--------|
| `PAUSE` | Pause a pool's borrowing function |
| `UNPAUSE` | Resume a paused pool's borrowing |
| `WHITELIST` | Enable LP rewards for a pool |
| `DEWHITELIST` | Disable LP rewards for a pool |

## Staking (Depositing Vote Tokens)

### Deposit Tokens

To participate in governance, deposit your governance tokens:

```solidity
// Approve controller to spend tokens
voteToken.approve(controllerAddress, amount);

// Deposit tokens
controller.depositVoteToken(amount);
```

### Benefits of Staking

1. **Voting Power** - Vote on proposals proportional to your stake
2. **Revenue Sharing** - Earn share of protocol fees
3. **LP Rewards** - Your balance is used for reward calculations

### Withdraw Tokens

```solidity
controller.withdrawVoteToken(amount);
```

## Proposals

### Creating a Proposal

Any staker can create a proposal:

```solidity
controller.createProposal(
    poolAddress,    // Target pool (IPausable)
    Action.PAUSE,   // Action to take
    deadline        // Voting deadline timestamp
);
```

**Requirements:**
- Must have deposited vote tokens
- Target must be a valid pool address
- Deadline must be in the future

### Voting

Cast your vote by calling:

```solidity
controller.vote(proposalIdx);
```

Your vote weight equals your deposited token balance at the time of voting.

### Cancelling Vote

Change your mind? Cancel your vote:

```solidity
controller.cancel(proposalIdx);
```

This withdraws your votes from the proposal.

### Execution

Proposals execute automatically when:

1. **Threshold reached** - Votes exceed required percentage of total supply
2. **Deadline not passed** - Must execute before deadline
3. **Not already executed** - Can only execute once

**For WHITELIST/DEWHITELIST:**
- Additional requirement: Veto holder must approve

## Governance Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    Proposal Lifecycle                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. CREATE                                                       │
│     └─► Proposer creates proposal with target, action, deadline │
│                                                                  │
│  2. VOTE                                                         │
│     └─► Token holders vote with their stake                     │
│     └─► Votes accumulate toward threshold                       │
│                                                                  │
│  3. EXECUTE (automatic when threshold reached)                   │
│     └─► For PAUSE/UNPAUSE: Executes immediately                 │
│     └─► For WHITELIST/DEWHITELIST: Needs veto approval first    │
│                                                                  │
│  4. EXPIRED (if deadline passes without threshold)               │
│     └─► Proposal becomes inactive                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Revenue Sharing

### How It Works

Protocol fees are collected from pools and distributed to stakers:

1. Pools call `depositRevenue()` when collecting fees
2. Stakers can trigger snapshots to lock in distribution
3. Stakers claim their share based on balance at snapshot time

### Claiming Revenue

```solidity
// Claim revenue for a specific token
controller.claimToken(tokenAddress);
```

Your share is calculated as:

```
                    Your Balance at Snapshot
Your Revenue = ──────────────────────────────── × Collected Revenue
                Total Supply at Snapshot
```

### Revenue Tokens

Revenue can be in multiple tokens:
- Native token (VC/WVC)
- Stablecoins (USDT)
- Any ERC20 that pools collect fees in

## Veto Power

### Veto Holder Role

A special address (the "veto holder") has additional powers:

- Must approve WHITELIST and DEWHITELIST proposals
- Can transfer veto power to another address
- Acts as a safety mechanism for reward distribution

### Veto Approval

For whitelist actions, the veto holder must call:

```solidity
controller.approveVetoHolder(proposalIdx, true);  // Approve
controller.approveVetoHolder(proposalIdx, false); // Reject
```

### Transfer Veto Power

```solidity
controller.setVetoHolderAddress(newVetoHolder);
```

## Snapshots

### Account Snapshots

Your balance is snapshotted when you:
- Deposit tokens
- Withdraw tokens

### Token Snapshots

Protocol revenue snapshots are created when:
- `depositRevenue()` is called
- Anyone triggers a snapshot

## Example: Complete Governance Flow

### 1. Stake Tokens

```javascript
// Approve and stake 1000 tokens
const amount = ethers.utils.parseEther("1000");
await voteToken.approve(controllerAddress, amount);
await controller.depositVoteToken(amount);
```

### 2. Create Proposal

```javascript
// Create proposal to pause a pool
const deadline = Math.floor(Date.now() / 1000) + 86400 * 7; // 7 days
await controller.createProposal(poolAddress, 0, deadline); // 0 = PAUSE
```

### 3. Vote on Proposal

```javascript
// Vote on proposal index 0
await controller.vote(0);
```

### 4. Claim Revenue

```javascript
// Claim accumulated USDT revenue
await controller.claimToken(usdtAddress);
```

## LP Reward Distribution

### Whitelisted Pools

Pools whitelisted by governance can distribute rewards:

```solidity
// Called by whitelisted pool
controller.requestTokenDistribution(
    lpAddress,
    liquidity,
    duration,
    rewardCoefficient
);
```

### Reward Calculation

```
Reward = Liquidity × Duration × RewardCoefficient / ScalingFactor
```

This incentivizes:
- Larger liquidity deposits
- Longer holding periods
- Pools with higher reward coefficients

## Events

Track governance activity via events:

| Event | When Emitted |
|-------|--------------|
| `ProposalCreated` | New proposal created |
| `Voted` | Someone votes |
| `Cancelled` | Someone cancels vote |
| `Executed` | Proposal executes |
| `DepositedVoteToken` | Tokens staked |
| `WithdrawnVoteToken` | Tokens withdrawn |
| `TokenClaimed` | Revenue claimed |
| `VetoPowerTransfer` | Veto holder changed |
| `VetoHolderApproval` | Veto approved/rejected |

## Best Practices

### For Voters

1. **Review proposals carefully** - Understand the impact before voting
2. **Monitor deadlines** - Vote before proposals expire
3. **Claim regularly** - Don't let revenue accumulate unclaimed
4. **Stay informed** - Follow governance discussions

### For Proposers

1. **Build consensus** - Discuss proposals before creating
2. **Set reasonable deadlines** - Give time for voting
3. **Provide context** - Explain why the action is needed
4. **Consider timing** - Avoid creating during low activity

### For Stakers

1. **Long-term mindset** - Governance rewards patience
2. **Diversify claims** - Check all token types
3. **Monitor protocol** - Stay engaged with developments
4. **Participate actively** - Vote on important proposals

## Security Considerations

### Voting Power

- Larger stakes = more influence
- Whale addresses can significantly impact outcomes
- Consider delegation mechanisms for smaller holders

### Snapshot Gaming

- Balance at snapshot determines share
- Gaming attempts (deposit before, withdraw after) are tracked
- Sub-timestamp system prevents same-block manipulation

### Veto Protection

- Veto holder provides safety for reward distribution
- Can prevent malicious whitelist attempts
- Should be a trusted/decentralized entity

## Related

- [Controller Reference](../reference/contracts/controller.md)
- [Core Concepts](../overview/concepts.md)
- [Protocol Architecture](../overview/architecture.md)

# IController Interface

Interface for the Controller governance contract.

**Source:** `contracts/interfaces/IController.sol`

## Events

### ProposalCreated

```solidity
event ProposalCreated(
    uint256 proposalIdx,
    address indexed creator,
    IPausable indexed target,
    Action action,
    uint256 deadline
)
```

### Voted

```solidity
event Voted(
    uint256 indexed proposalIdx,
    address indexed voter,
    uint256 votes,
    uint256 newTotalVotes
)
```

### Cancelled

```solidity
event Cancelled(
    uint256 indexed proposalIdx,
    address indexed voter,
    uint256 votes,
    uint256 newTotalVotes
)
```

### Executed

```solidity
event Executed(
    uint256 indexed proposalIdx,
    uint256 totalVotes,
    uint256 voteTokenTotalSupply
)
```

### DepositedVoteToken

```solidity
event DepositedVoteToken(
    address indexed account,
    uint256 amount,
    uint256 newBalance,
    uint256 newTotalSupply,
    uint256 subTimestamp
)
```

### WithdrawnVoteToken

```solidity
event WithdrawnVoteToken(
    address indexed account,
    uint256 amount,
    uint256 newBalance,
    uint256 newTotalSupply,
    uint256 subTimestamp
)
```

### TokenSnapshotPerformed

```solidity
event TokenSnapshotPerformed(
    IERC20 indexed tokenId,
    uint256 tokenSnapshotIdx,
    uint256 voteTokenTotalSupply,
    uint256 collectedRevenue,
    uint256 subTimestamp
)
```

### TokenClaimed

```solidity
event TokenClaimed(
    IERC20 indexed tokenId,
    address indexed account,
    uint256 indexed tokenSnapshotIdx,
    uint256 accountSnapshotIdx,
    uint256 amount,
    uint256 totalClaimedRevenue
)
```

### VetoPowerTransfer

```solidity
event VetoPowerTransfer(
    address oldHolder,
    address newHolder
)
```

### VetoHolderApproval

```solidity
event VetoHolderApproval(
    uint256 indexed proposalIdx,
    bool approved
)
```

### Reward

```solidity
event Reward(
    address account,
    uint128 liquidity,
    uint32 duration,
    uint96 rewardCoefficient,
    uint256 amount
)
```

## Enums

### Action

```solidity
enum Action {
    PAUSE,       // Pause pool (stops borrowing)
    UNPAUSE,     // Unpause pool
    WHITELIST,   // Enable pool for LP rewards
    DEWHITELIST  // Disable pool LP rewards
}
```

## Structs

### Proposal

```solidity
struct Proposal {
    IPausable target;                        // Target contract
    Action action;                           // Action to execute
    uint256 totalVotes;                      // Accumulated votes
    address vetoApprover;                    // Veto holder address (for whitelist)
    mapping(address => uint256) votesByAddress; // Votes per address
    bool executed;                           // Execution status
    uint256 deadline;                        // Voting deadline
}
```

### TokenSnapshot

```solidity
struct TokenSnapshot {
    uint256 voteTokenTotalSupply; // Total staked at snapshot
    uint256 collectedRevenue;     // Revenue collected
    uint256 claimedRevenue;       // Revenue claimed
    uint256 timestamp;            // Snapshot time
    uint256 subTimestamp;         // Sub-timestamp for ordering
    mapping(address => bool) claimed; // Claim status per user
}
```

### AccountSnapshot

```solidity
struct AccountSnapshot {
    uint256 voteTokenBalance; // Balance at snapshot
    uint256 timestamp;        // Snapshot time
    uint256 subTimestamp;     // Sub-timestamp for ordering
}
```

## Functions

### depositRevenue

```solidity
function depositRevenue(
    IERC20 _token,
    uint256 _amount
) external payable;
```

Called by pools to deposit protocol fees for distribution to stakers.

### requestTokenDistribution

```solidity
function requestTokenDistribution(
    address _account,
    uint128 _liquidity,
    uint32 _duration,
    uint96 _rewardCoefficient
) external;
```

Called by whitelisted pools to request LP reward distribution.

## Inheritance

```solidity
interface IController is IERC165
```

Implements ERC-165 for interface detection:

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool);
```

## Related

- [Controller Reference](../contracts/controller.md)
- [Governance Guide](../../guides/governance.md)

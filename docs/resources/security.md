# Security

This document covers security considerations for VinuFinance protocol.

## Security Model

### Design Philosophy

VinuFinance is designed with security as a primary concern:

1. **Simplicity** - Minimal attack surface through focused functionality
2. **Isolation** - Each pool operates independently
3. **Time-locks** - Minimum periods prevent flash loan exploits
4. **Access Control** - Role-based permissions for sensitive functions
5. **Pausability** - Emergency stop capability via governance

## Contract Security

### BasePool

#### Protected Functions

| Function | Protection |
|----------|------------|
| `pause()` | Only Controller |
| `unpause()` | Only Controller |

#### Safety Mechanisms

1. **Minimum LP Period** (120 seconds)
   - Prevents flash loan attacks on LP shares
   - Cannot remove liquidity immediately after adding

2. **Minimum Loan Tenor** (86,400 seconds)
   - Ensures meaningful loan duration
   - Prevents same-block borrow/default attacks

3. **Slippage Protection**
   - `_minLoan` and `_maxRepay` parameters
   - Protects against sandwich attacks

4. **Deadline Validation**
   - Transactions revert if deadline passed
   - Prevents stale transactions from executing

### Controller

#### Protected Functions

| Function | Protection |
|----------|------------|
| `requestTokenDistribution()` | Only whitelisted pools |
| `setVetoHolderAddress()` | Only current veto holder |
| `approveVetoHolder()` | Only veto holder |

#### Governance Safeguards

1. **Veto Power**
   - Whitelist/dewhitelist requires veto approval
   - Prevents malicious reward distributions

2. **Snapshot System**
   - Sub-timestamp prevents same-block manipulation
   - Accurate balance tracking for revenue distribution

3. **Proposal Deadlines**
   - Time-bounded voting windows
   - Prevents indefinite proposal accumulation

## Known Risks

### Economic Risks

#### Collateral Value Risk

If collateral value drops significantly below loan value when a borrower defaults, LPs receive collateral worth less than the loan amount.

**Mitigation:**
- Conservative maxLoanPerColl settings
- Liquid collateral tokens only
- Regular monitoring of collateral prices

#### Interest Rate Manipulation

Large deposits/withdrawals can affect interest rates.

**Mitigation:**
- Three-region rate model smooths changes
- Large operations have limited rate impact
- Rates are bounded (r1 to r2)

#### Liquidity Risk

Large withdrawals may temporarily impact available liquidity.

**Mitigation:**
- Liquidity is only locked in active loans
- Minimum liquidity checks in some operations
- LP share system ensures fair distribution

### Technical Risks

#### Smart Contract Bugs

Undiscovered vulnerabilities may exist.

**Mitigation:**
- Code review and testing
- Simple, auditable architecture
- Pause mechanism for emergencies

#### Oracle-Free Design

VinuFinance does not use price oracles, eliminating oracle manipulation risks but introducing different tradeoffs.

**Tradeoff:**
- No oracle = no oracle attacks
- But: maxLoanPerColl is static, not dynamic based on prices

#### Reentrancy

External calls in repay and claim functions.

**Mitigation:**
- Checks-effects-interactions pattern
- State updates before external calls
- Tested against reentrancy attacks

## Security Best Practices

### For Users

#### General

1. **Verify contracts** - Always verify you're interacting with official contracts
2. **Check parameters** - Review transaction parameters before signing
3. **Use hardware wallet** - For significant funds
4. **Start small** - Test with small amounts first

#### For LPs

1. **Understand risks** - Know what collateral you may receive
2. **Monitor positions** - Track your LP shares and claimable amounts
3. **Diversify** - Don't put all funds in one pool

#### For Borrowers

1. **Calculate break-even** - Know when repaying makes sense
2. **Set reminders** - Track loan expiry dates
3. **Use slippage protection** - Set appropriate minLoan and maxRepay

### For Operators

#### Deployment

1. **Multi-sig ownership** - Use multi-sig for veto holder
2. **Verify contracts** - Always verify on block explorer
3. **Test thoroughly** - Full testing before mainnet
4. **Document everything** - Keep deployment records

#### Operations

1. **Monitor events** - Track all contract events
2. **Regular audits** - Periodic security reviews
3. **Incident response plan** - Have procedures ready
4. **Communication channels** - Clear user communication

## Emergency Procedures

### Pausing a Pool

If a vulnerability is discovered:

1. **Create PAUSE proposal** via Controller
2. **Vote with majority** to reach threshold
3. **Pool borrowing is disabled** immediately on execution
4. **Existing loans** can still be repaid
5. **LPs can claim** and remove liquidity

```javascript
// Emergency pause
await controller.createProposal(
    poolAddress,
    0,  // PAUSE
    Math.floor(Date.now() / 1000) + 3600  // 1 hour deadline
);
await controller.vote(proposalIdx);
```

### Emergency Withdrawal

The EmergencyWithdrawal contract provides last-resort fund recovery:

1. **Only for extreme emergencies** - Pool contract catastrophically broken
2. **Requires escrow setup** - Manual process
3. **Full audit trail** - All actions logged

See [EmergencyWithdrawal Reference](../reference/contracts/emergency-withdrawal.md).

## Audit Status

### Code Review

| Item | Status |
|------|--------|
| BasePool | Reviewed |
| Controller | Reviewed |
| MultiClaim | Reviewed |
| EmergencyWithdrawal | Reviewed |

### Test Coverage

| Contract | Coverage |
|----------|----------|
| BasePool | >90% |
| Controller | >90% |
| Helpers | >85% |

### Known Issues

All known issues from audits have been addressed. See audit reports for details.

## Bug Bounty

### Scope

- BasePool.sol
- Controller.sol
- MultiClaim.sol
- EmergencyWithdrawal.sol
- All interface contracts

### Rewards

| Severity | Reward |
|----------|--------|
| Critical | Up to $50,000 |
| High | Up to $10,000 |
| Medium | Up to $2,000 |
| Low | Up to $500 |

### Reporting

Report vulnerabilities to: security@vinufinance.io

Include:
1. Detailed description
2. Steps to reproduce
3. Potential impact
4. Suggested fix (optional)

### Rules

- First reporter receives reward
- Public disclosure only after fix
- No exploitation of live contracts
- Good faith effort to report privately

## Related

- [Controller Reference](../reference/contracts/controller.md)
- [Emergency Withdrawal](../reference/contracts/emergency-withdrawal.md)
- [Governance Guide](../guides/governance.md)

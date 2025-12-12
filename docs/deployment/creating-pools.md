# Creating Pools

This guide explains how to create and configure new lending pools in VinuFinance.

## Overview

Each BasePool is a standalone lending market with specific:
- Token pair (loan currency + collateral currency)
- Interest rate parameters
- Loan terms (duration, LTV ratio)
- Fee structure

## Pool Parameters

### Token Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `loanCcyToken` | address | Token borrowed by users (e.g., USDT) |
| `collCcyToken` | address | Token pledged as collateral (e.g., WVC) |

**Considerations:**
- Loan token should have stable value (stablecoins preferred)
- Collateral token should have liquid markets for LPs to sell defaults
- Verify token decimals match your calculations

### Loan Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `loanTenor` | uint256 | Loan duration in seconds |
| `maxLoanPerColl` | uint256 | Maximum loan per unit of collateral |
| `minLoan` | uint256 | Minimum loan amount |

#### Loan Tenor

Common durations:

| Duration | Seconds |
|----------|---------|
| 1 day | 86,400 |
| 7 days | 604,800 |
| 14 days | 1,209,600 |
| 30 days | 2,592,000 |
| 90 days | 7,776,000 |

**Minimum:** 86,400 seconds (1 day) - enforced by `MIN_TENOR`

#### Max Loan Per Collateral

This determines the effective LTV ratio:

```
                    Loan Amount Received
Effective LTV = ──────────────────────────────
                Collateral Value (at current price)
```

**Example:**
- If WVC price = $2.00
- maxLoanPerColl = 0.5 (in loan token units per collateral unit)
- For 100 WVC pledged: max loan = 100 × 0.5 = 50 USDT
- Effective LTV = 50 / (100 × 2) = 25%

**Setting maxLoanPerColl:**
```javascript
// For 50% LTV at current prices
const collateralPrice = 2.0;    // $2 per WVC
const desiredLTV = 0.5;         // 50%
const maxLoanPerColl = collateralPrice * desiredLTV; // 1.0
```

### Interest Rate Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `r1` | uint256 | Rate at 0% utilization |
| `r2` | uint256 | Rate at 100% utilization |
| `liquidityBnd1` | uint256 | First boundary (start of linear region) |
| `liquidityBnd2` | uint256 | Second boundary (end of linear region) |

#### Interest Rate Model

```
Rate at 0% util ────────────────► r1
                                   │
                                   │ Hyperbolic decrease
                                   │
Rate at bnd1/total ◄───────────────┤
                                   │
                                   │ Linear increase
                                   │
Rate at bnd2/total ◄───────────────┤
                                   │
                                   │ Constant
                                   │
Rate at 100% util ────────────────► r2
```

#### Example Configuration

For a pool with moderate risk tolerance:

```javascript
const BASE = ethers.utils.parseUnits("1", 18);

// Interest rates (annualized, in BASE)
const r1 = BASE.mul(2).div(100);   // 2% at low utilization
const r2 = BASE.mul(15).div(100);  // 15% at high utilization

// Liquidity boundaries (in loan token units)
const liquidityBnd1 = ethers.utils.parseUnits("10000", 6);  // 10k USDT
const liquidityBnd2 = ethers.utils.parseUnits("100000", 6); // 100k USDT
```

**Rate behavior:**
- 0-10k liquidity: Rates decrease hyperbolically from r2 toward linear region
- 10k-100k liquidity: Rates increase linearly
- 100k+ liquidity: Rates stay constant at r2

### Fee Parameters

| Parameter | Type | Description | Max |
|-----------|------|-------------|-----|
| `creatorFee` | uint256 | Fee to pool creator | 3% (MAX_CREATOR_FEE) |

The creator fee is taken from each loan as a percentage.

**Example:**
```javascript
// 1% creator fee
const creatorFee = BASE.mul(1).div(100);
```

### Governance Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `poolController` | address | Controller contract address |
| `rewardCoefficient` | uint96 | Multiplier for LP rewards |

#### Reward Coefficient

Higher coefficients = more LP rewards (if pool is whitelisted):

```javascript
// Standard reward coefficient
const rewardCoefficient = BASE;  // 1x rewards

// Premium pool with 2x rewards
const rewardCoefficient = BASE.mul(2);  // 2x rewards
```

## Complete Example

### Pool Configuration

```javascript
const config = {
    // Tokens
    loanToken: "0x...",      // USDT
    collToken: "0x...",      // WVC

    // Loan terms
    loanTenor: 2592000,      // 30 days
    maxLoanPerColl: ethers.utils.parseUnits("0.5", 18),  // 0.5 USDT per WVC
    minLoan: ethers.utils.parseUnits("100", 6),  // 100 USDT min

    // Interest rates
    r1: ethers.utils.parseUnits("0.02", 18),  // 2%
    r2: ethers.utils.parseUnits("0.15", 18),  // 15%
    liquidityBnd1: ethers.utils.parseUnits("10000", 6),   // 10k USDT
    liquidityBnd2: ethers.utils.parseUnits("100000", 6),  // 100k USDT

    // Fees
    creatorFee: ethers.utils.parseUnits("0.01", 18),  // 1%

    // Governance
    controller: "0x...",
    rewardCoefficient: ethers.utils.parseUnits("1", 18)  // 1x
};
```

### Deployment Script

```javascript
async function deployPool(config) {
    const BasePool = await ethers.getContractFactory("BasePool");

    const pool = await BasePool.deploy(
        config.loanToken,
        config.collToken,
        config.loanTenor,
        config.maxLoanPerColl,
        config.r1,
        config.r2,
        config.liquidityBnd1,
        config.liquidityBnd2,
        config.minLoan,
        config.creatorFee,
        config.controller,
        config.rewardCoefficient
    );

    await pool.deployed();

    console.log("Pool deployed:", pool.address);
    return pool;
}
```

## Pool Templates

### Conservative Stablecoin Pool

Low risk, lower returns:

```javascript
{
    loanTenor: 2592000,          // 30 days
    maxLoanPerColl: 0.3,         // 30% effective LTV
    r1: 0.01,                    // 1%
    r2: 0.08,                    // 8%
    liquidityBnd1: 100000,       // 100k
    liquidityBnd2: 500000,       // 500k
    minLoan: 1000,               // 1000 USDT
    creatorFee: 0.005            // 0.5%
}
```

### Standard Pool

Balanced risk/reward:

```javascript
{
    loanTenor: 2592000,          // 30 days
    maxLoanPerColl: 0.5,         // 50% effective LTV
    r1: 0.02,                    // 2%
    r2: 0.15,                    // 15%
    liquidityBnd1: 10000,        // 10k
    liquidityBnd2: 100000,       // 100k
    minLoan: 100,                // 100 USDT
    creatorFee: 0.01             // 1%
}
```

### Aggressive Short-Term Pool

Higher risk, higher returns:

```javascript
{
    loanTenor: 604800,           // 7 days
    maxLoanPerColl: 0.7,         // 70% effective LTV
    r1: 0.05,                    // 5%
    r2: 0.30,                    // 30%
    liquidityBnd1: 5000,         // 5k
    liquidityBnd2: 25000,        // 25k
    minLoan: 50,                 // 50 USDT
    creatorFee: 0.02             // 2%
}
```

## Parameter Validation

### Automatic Checks

The contract validates:

```solidity
require(_loanTenor >= MIN_TENOR, "Loan tenor too small.");
require(_liquidityBnd2 > _liquidityBnd1, "Invalid liquidity bounds.");
require(_creatorFee <= MAX_CREATOR_FEE, "Creator fee too high.");
```

### Manual Verification

Before deploying, verify:

1. **Token decimals**: Ensure amounts match token decimals
2. **Rate reasonableness**: Compare to market rates
3. **LTV safety**: Consider collateral volatility
4. **Minimum viable liquidity**: liquidityBnd1 should be achievable
5. **Fee competitiveness**: Compare to other DeFi protocols

## Post-Deployment

### Seed Liquidity

Add initial liquidity to bootstrap the pool:

```javascript
// Approve and add liquidity
await loanToken.approve(pool.address, seedAmount);
await pool.addLiquidity(
    myAddress,
    seedAmount,
    deadline,
    0  // No referral
);
```

### Whitelist for Rewards

Create governance proposal to whitelist:

```javascript
await controller.createProposal(
    pool.address,
    2,  // WHITELIST action
    deadline
);
```

### Monitor Initial Activity

Watch for:
- First loans
- Interest rate behavior
- Liquidity changes
- Any unexpected behavior

## Multiple Pools

You can deploy multiple pools with different configurations:

```javascript
// Deploy USDT/WVC 30-day pool
const pool30d = await deployPool({
    ...baseConfig,
    loanTenor: 2592000
});

// Deploy USDT/WVC 7-day pool
const pool7d = await deployPool({
    ...baseConfig,
    loanTenor: 604800,
    r1: ethers.utils.parseUnits("0.03", 18),
    r2: ethers.utils.parseUnits("0.20", 18)
});

// Deploy USDT/WBTC pool
const poolBTC = await deployPool({
    ...baseConfig,
    collToken: wbtcAddress,
    maxLoanPerColl: ethers.utils.parseUnits("30000", 18)  // Higher for BTC
});
```

## Related

- [Deployment Overview](overview.md)
- [VinuChain Deployment](vinuchain.md)
- [Interest Rates](../overview/interest-rates.md)
- [BasePool Reference](../reference/contracts/base-pool.md)

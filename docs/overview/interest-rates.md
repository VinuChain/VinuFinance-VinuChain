# Interest Rates

VinuFinance uses a dynamic interest rate model that adjusts based on pool liquidity utilization.

## Rate Model Overview

The interest rate is defined as a **piecewise function** with three distinct regions:

```
Interest
Rate (r)
    │
    │
r1×L1│─────┐
 /L  │      ╲
    │       ╲
r1  ├────────╲
    │         ╲  Linear interpolation
    │          ╲
    │           ╲
r2  ├────────────────────────────────
    │            │      │
    └────────────┴──────┴───────────► Available Liquidity
              L1       L2

    └─────────┘  └──────┘  └─────────┘
     Hyperbolic   Target     Constant
       Region     Region      Region
```

## Rate Regions

### 1. Low Liquidity Region (Hyperbolic)

When available liquidity is below `liquidityBnd1`:

```
rate = r1 × liquidityBnd1 / liquidity
```

**Behavior:**
- Rate increases hyperbolically as liquidity decreases
- Creates strong incentive for LPs to deposit
- Protects pool from being drained

### 2. Target Range (Linear)

When liquidity is between `liquidityBnd1` and `liquidityBnd2`:

```
rate = r2 + (r1 - r2) × (liquidityBnd2 - liquidity) / (liquidityBnd2 - liquidityBnd1)
```

**Behavior:**
- Linear interpolation between r1 and r2
- Smooth transition as utilization changes
- This is the "normal" operating range

### 3. High Liquidity Region (Constant)

When available liquidity exceeds `liquidityBnd2`:

```
rate = r2
```

**Behavior:**
- Rate stays at minimum (r2)
- Encourages borrowing when liquidity is abundant
- Maintains baseline yield for LPs

## Rate Parameters

| Parameter | Description | Typical Value |
|-----------|-------------|---------------|
| `r1` | Rate at start of target range | 5-15% (per tenor) |
| `r2` | Minimum rate (end of target range) | 1-5% (per tenor) |
| `liquidityBnd1` | Start of target range | 10-20% of min liquidity |
| `liquidityBnd2` | End of target range | 50-80% of target liquidity |

**Important:** Rates are denominated **per loan tenor**, not annualized.

## Calculating Repayment Amount

The repayment amount uses the **average rate** between pre-borrow and post-borrow liquidity:

```solidity
uint256 avgRate = (getRate(totalLiquidity - minLiquidity) +
                   getRate(postLiquidity - minLiquidity)) / 2;

uint256 repayment = (loan * (BASE + avgRate)) / BASE;
```

This ensures:
- Fair pricing regardless of loan size
- Larger loans don't get artificially cheap rates
- Rate reflects actual pool impact

## Example Calculations

### Example 1: Small Loan in Target Range

**Pool State:**
- Total Liquidity: 100,000 USDT
- Min Liquidity: 10,000 USDT
- Available: 90,000 USDT
- r1: 10% (0.1 × 10^18)
- r2: 2% (0.02 × 10^18)
- L1: 20,000 USDT
- L2: 80,000 USDT

**Loan Request:**
- Loan Amount: 5,000 USDT
- Post-borrow Available: 85,000 USDT

**Rate Calculation:**
```
Pre-rate (90,000 in high region):
rate_pre = r2 = 2%

Post-rate (85,000 in high region):
rate_post = r2 = 2%

Average rate = (2% + 2%) / 2 = 2%

Repayment = 5,000 × 1.02 = 5,100 USDT
Interest = 100 USDT
```

### Example 2: Large Loan Crossing Regions

**Pool State:** Same as above

**Loan Request:**
- Loan Amount: 50,000 USDT
- Post-borrow Available: 40,000 USDT (in target range)

**Rate Calculation:**
```
Pre-rate (90,000 in high region):
rate_pre = r2 = 2%

Post-rate (40,000 in target range):
rate_post = 2% + (10% - 2%) × (80,000 - 40,000) / (80,000 - 20,000)
         = 2% + 8% × (40,000 / 60,000)
         = 2% + 5.33%
         = 7.33%

Average rate = (2% + 7.33%) / 2 = 4.67%

Repayment = 50,000 × 1.0467 = 52,335 USDT
Interest = 2,335 USDT
```

## Implementation

```solidity
function getRate(uint256 _liquidity) internal view returns (uint256 rate) {
    if (_liquidity < liquidityBnd1) {
        // Hyperbolic region
        rate = (r1 * liquidityBnd1) / _liquidity;
    } else if (_liquidity <= liquidityBnd2) {
        // Linear target range
        rate = r2 + ((r1 - r2) * (liquidityBnd2 - _liquidity)) /
               (liquidityBnd2 - liquidityBnd1);
    } else {
        // Constant region
        rate = r2;
    }
}
```

## Converting to APY

Since rates are per-tenor (not annualized), convert to APY:

```javascript
// Loan tenor in seconds (e.g., 30 days)
const tenorSeconds = 30 * 24 * 60 * 60;
const secondsPerYear = 365 * 24 * 60 * 60;
const periodsPerYear = secondsPerYear / tenorSeconds;

// Rate per tenor (e.g., 2%)
const ratePerTenor = 0.02;

// Simple annualized rate
const simpleAPR = ratePerTenor * periodsPerYear;

// Compound APY
const APY = Math.pow(1 + ratePerTenor, periodsPerYear) - 1;
```

## Rate Constraints

| Constraint | Value | Reason |
|------------|-------|--------|
| `r1 > r2` | Required | Ensures decreasing rate with liquidity |
| `r2 > 0` | Required | Maintains minimum yield |
| `liquidityBnd2 > liquidityBnd1` | Required | Valid target range |
| `liquidityBnd1 > 0` | Required | Prevents division by zero |

## Related

- [Core Concepts](concepts.md)
- [Borrowing Guide](../guides/borrowing.md)
- [BasePool Reference](../reference/contracts/base-pool.md)

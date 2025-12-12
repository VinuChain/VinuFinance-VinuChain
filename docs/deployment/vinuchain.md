# VinuChain Deployment

This guide covers VinuFinance deployment specifics for VinuChain.

## VinuChain Network

| Property | Value |
|----------|-------|
| Chain ID | 206 |
| Native Token | VC (VinuCoin) |
| Wrapped Native | WVC (Wrapped VinuCoin) |
| Block Time | ~3 seconds |
| Consensus | Proof of Authority |

## Network Configuration

### Hardhat Config

```javascript
// hardhat.config.js
module.exports = {
    networks: {
        vinuchain: {
            url: process.env.VINUCHAIN_RPC_URL || "https://vinuchain-rpc.com",
            chainId: 206,
            accounts: [process.env.PRIVATE_KEY],
            gasPrice: "auto"
        }
    }
};
```

### MetaMask Setup

Add VinuChain to MetaMask:

| Setting | Value |
|---------|-------|
| Network Name | VinuChain |
| RPC URL | https://vinuchain-rpc.com |
| Chain ID | 206 |
| Symbol | VC |
| Explorer | https://explorer.vinuchain.com |

## Token Addresses

### Core Tokens

| Token | Address | Decimals |
|-------|---------|----------|
| WVC (Wrapped VC) | `0x...` | 18 |
| USDT | `0x...` | 6 |
| VINU (Governance) | `0x...` | 18 |

*Note: Replace with actual deployed addresses*

## Deployment Script

### Complete Deployment

```javascript
// scripts/deploy-vinuchain.js
const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying to VinuChain with:", deployer.address);
    console.log("Balance:", ethers.utils.formatEther(
        await deployer.getBalance()
    ), "VC");

    // Token addresses (update these)
    const VINU_ADDRESS = "0x...";
    const WVC_ADDRESS = "0x...";
    const USDT_ADDRESS = "0x...";

    // Deploy Controller
    console.log("\n1. Deploying Controller...");
    const Controller = await ethers.getContractFactory("Controller");
    const controller = await Controller.deploy(
        VINU_ADDRESS,
        deployer.address  // Temporary veto holder
    );
    await controller.deployed();
    console.log("Controller:", controller.address);

    // Deploy BasePool (USDT/WVC)
    console.log("\n2. Deploying BasePool (USDT/WVC)...");
    const BasePool = await ethers.getContractFactory("BasePool");
    const pool = await BasePool.deploy(
        USDT_ADDRESS,                        // Loan token
        WVC_ADDRESS,                         // Collateral token
        2592000,                             // 30 days
        ethers.utils.parseUnits("0.5", 18),  // maxLoanPerColl
        ethers.utils.parseUnits("0.02", 18), // r1 = 2%
        ethers.utils.parseUnits("0.15", 18), // r2 = 15%
        ethers.utils.parseUnits("10000", 6), // 10k USDT bnd1
        ethers.utils.parseUnits("100000", 6),// 100k USDT bnd2
        ethers.utils.parseUnits("100", 6),   // 100 USDT minLoan
        ethers.utils.parseUnits("0.01", 18), // 1% creator fee
        controller.address,
        ethers.utils.parseUnits("1", 18)     // reward coefficient
    );
    await pool.deployed();
    console.log("BasePool (USDT/WVC):", pool.address);

    // Deploy helpers
    console.log("\n3. Deploying helpers...");
    const MultiClaim = await ethers.getContractFactory("MultiClaim");
    const multiClaim = await MultiClaim.deploy();
    await multiClaim.deployed();
    console.log("MultiClaim:", multiClaim.address);

    // Summary
    console.log("\n========== DEPLOYMENT SUMMARY ==========");
    console.log("Network: VinuChain (chainId: 206)");
    console.log("Controller:", controller.address);
    console.log("BasePool:", pool.address);
    console.log("MultiClaim:", multiClaim.address);
    console.log("=========================================");

    // Save addresses
    const fs = require("fs");
    const addresses = {
        network: "vinuchain",
        chainId: 206,
        deployer: deployer.address,
        timestamp: new Date().toISOString(),
        contracts: {
            Controller: controller.address,
            "BasePool_USDT_WVC": pool.address,
            MultiClaim: multiClaim.address
        }
    };
    fs.writeFileSync(
        "deployments/vinuchain.json",
        JSON.stringify(addresses, null, 2)
    );
    console.log("\nAddresses saved to deployments/vinuchain.json");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
```

### Run Deployment

```bash
npx hardhat run scripts/deploy-vinuchain.js --network vinuchain
```

## Contract Verification

### Using Hardhat

```bash
# Verify Controller
npx hardhat verify --network vinuchain \
    CONTROLLER_ADDRESS \
    "VINU_ADDRESS" \
    "VETO_HOLDER_ADDRESS"

# Verify BasePool
npx hardhat verify --network vinuchain \
    POOL_ADDRESS \
    "USDT_ADDRESS" "WVC_ADDRESS" \
    "2592000" \
    "500000000000000000" \
    "20000000000000000" \
    "150000000000000000" \
    "10000000000" \
    "100000000000" \
    "100000000" \
    "10000000000000000" \
    "CONTROLLER_ADDRESS" \
    "1000000000000000000"
```

### Manual Verification

If automatic verification fails:

1. Go to VinuChain Explorer
2. Navigate to contract address
3. Click "Verify Contract"
4. Select "Solidity (Standard JSON-Input)"
5. Upload build artifacts from `artifacts/build-info/`

## Gas Costs on VinuChain

VinuChain has low gas costs:

| Operation | Estimated Gas | Cost (at 1 gwei) |
|-----------|---------------|------------------|
| Controller Deploy | ~3M | ~0.003 VC |
| BasePool Deploy | ~4.5M | ~0.0045 VC |
| Add Liquidity | ~200k | ~0.0002 VC |
| Borrow | ~250k | ~0.00025 VC |
| Repay | ~150k | ~0.00015 VC |
| Claim | ~100k + 50k/loan | Variable |

## Recommended Pool Parameters

### Conservative Pool (USDT/WVC)

```javascript
{
    loanTenor: 2592000,        // 30 days
    maxLoanPerColl: 0.3,       // 30% LTV
    r1: 0.02,                  // 2% base rate
    r2: 0.12,                  // 12% max rate
    liquidityBnd1: 50000,      // 50k USDT
    liquidityBnd2: 200000,     // 200k USDT
    minLoan: 100,              // 100 USDT
    creatorFee: 0.005          // 0.5%
}
```

### Aggressive Pool (USDT/WVC)

```javascript
{
    loanTenor: 604800,         // 7 days
    maxLoanPerColl: 0.6,       // 60% LTV
    r1: 0.05,                  // 5% base rate
    r2: 0.25,                  // 25% max rate
    liquidityBnd1: 10000,      // 10k USDT
    liquidityBnd2: 50000,      // 50k USDT
    minLoan: 50,               // 50 USDT
    creatorFee: 0.01           // 1%
}
```

## Post-Deployment Checklist

### Immediate Actions

- [ ] Verify all contracts on explorer
- [ ] Transfer veto holder to multisig
- [ ] Test addLiquidity with small amount
- [ ] Test borrow with small amount
- [ ] Verify interest rate calculation
- [ ] Test repay and claim

### Governance Setup

- [ ] Stake VINU tokens in Controller
- [ ] Create whitelist proposal for pool
- [ ] Vote on whitelist proposal
- [ ] Verify LP rewards after whitelist

### Frontend Integration

- [ ] Update contract addresses in frontend config
- [ ] Test all UI flows on mainnet
- [ ] Verify transaction signing
- [ ] Test wallet connections

## Monitoring

### Key Metrics

Monitor these on VinuChain:

1. **Pool Utilization**: totalLiquidity vs active loans
2. **Interest Rates**: Current rates vs boundaries
3. **Default Rate**: Percentage of loans not repaid
4. **TVL**: Total value locked across pools

### Event Monitoring

Set up event listeners:

```javascript
// Monitor new loans
pool.on("Borrow", (borrower, loanIdx, collateral, loanAmount, ...) => {
    console.log(`New loan: ${loanIdx} for ${loanAmount}`);
});

// Monitor liquidity changes
pool.on("AddLiquidity", (lp, amount, shares, ...) => {
    console.log(`LP ${lp} added ${amount}`);
});
```

## Emergency Procedures

### Pause Pool

```javascript
// Create PAUSE proposal
await controller.createProposal(
    poolAddress,
    0,  // PAUSE action
    Math.floor(Date.now() / 1000) + 86400
);

// Vote with majority
await controller.vote(proposalIdx);
```

### Emergency Contact

In case of critical issues:
1. Immediately pause affected pools
2. Document the issue
3. Communicate with users via official channels
4. Engage security researchers if needed

## Related

- [Deployment Overview](overview.md)
- [Creating Pools](creating-pools.md)
- [Governance Guide](../guides/governance.md)

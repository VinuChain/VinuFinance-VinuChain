require("@nomiclabs/hardhat-ethers")
require('solidity-docgen');
import { HardhatUserConfig } from "hardhat/config";
import "@nomiclabs/hardhat-ethers"
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-contract-sizer"

export default{
    defaultNetwork: "hardhat",
    solidity: {
        version: "0.8.1",
        sourcesDir: 'contracts/solidity',
        settings: {
            optimizer: {
            enabled: true,
            runs: 200,
            details: { yul: false },
            },
        },
    },
    allowUnlimitedContractSize: true,
    contractSizer: {
        runOnCompile: true
    },
    networks: {
        hardhat: {
            accounts: {
                count: 2000
            }
        }
    }
}
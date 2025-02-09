require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-verify"); 
require("dotenv").config();

module.exports = {
  solidity: "0.8.20",
  networks: {
    mainnet: {
      url: process.env.MAINNET_RPC_URL || "",
      accounts: process.env.DEPLOYER_PK 
        ? [process.env.DEPLOYER_PK, process.env.DEVELOPER_PK, process.env.LIQUIDITY_PK, process.env.REWARDS_PK].filter(Boolean)
        : [],
    },
  },
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_API_KEY, 
    },
  },
};

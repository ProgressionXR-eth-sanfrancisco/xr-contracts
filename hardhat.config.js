require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy");
require("dotenv").config(); // For environment variables

module.exports = {
  solidity: "0.8.20",
  namedAccounts: {
    deployer: {
      default: 0, // The first account in the mnemonic will be used as deployer
    },
  },
  networks: {
    hardhat: {
      chainId: 1337, // Local Hardhat network
    },
    ambrosusMainnet: {
      url: process.env.AMBROSUS_RPC_URL || "https://network.ambrosus.io/",
      chainId: 16718, // AirDAO Ambrosus Mainnet
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
    ambrosusTestnet: {
      url: "https://network.ambrosus-test.io",
      chainId: 22040,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
    // skale: {
    //   url: "https://testnet.skalenodes.com/v1/lanky-ill-funny-testnet",
    //   chainId: 37084624,
    //   accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    // },
  },
};

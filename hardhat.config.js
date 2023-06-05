require('dotenv').config();
require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: '0.8.18',
  networks: {
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_SEPOLIA_KEY}`,
      accounts: [`0x${process.env.PRIVATE_KEY}`]
    }
  },
  settings: {
    optimizer: {
      enabled: true,
      runs: 1000,
    },
  }
};
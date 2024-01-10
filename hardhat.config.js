require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades');

require('dotenv').config();

require("@openzeppelin/hardhat-upgrades");

// ...

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.10",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
      throwOnTransactionFailures: true,
      throwOnCallFailures: true,
      allowUnlimitedContractSize: true,
      blockGasLimit: 0x1fffffffffffff
},
    polygon_mumbai: {
      url: "https://polygon-mumbai.g.alchemy.com/v2/nyjFGAVD43FsUCE8n23DV424pCSBUIT6",
      accounts: [process.env.PRIVATE_KEY],
      gas: 2100000, 
      gasPrice: 8000000000,
      throwOnTransactionFailures: true,
      throwOnCallFailures: true,
      allowUnlimitedContractSize: true,
      blockGasLimit: 0x1fffffffffffff

    }
  },
};
var HDWalletProvider = require("@truffle/hdwallet-provider");

module.exports = {
  networks: {
    // Development
    development: {
      host: "127.0.0.1",
      port: 9545,
      network_id: "*"
    },
    // Integration tests
    localhost: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "15"
    },
    ropsten: {
      provider: () => new HDWalletProvider(
        [process.env.PRIVATE_KEY],
        "https://ropsten.infura.io/v3/".concat(process.env.INFURA_PROJECT_ID)
      ),
      network_id: 3,
      gas: 8000000,
      gasPrice: 50000000000
    },
    goerli: {
      provider: () => new HDWalletProvider(
        [process.env.PRIVATE_KEY],
        "https://goerli.infura.io/v3/".concat(process.env.INFURA_PROJECT_ID)
      ),
      network_id: 5,
      gas: 8000000,
      gasPrice: 50000000000
    }
  },
  mocha: {
    useColors: true
  },
  compilers: {
    solc: {
      version: "0.8.17",
      optimizer: {
        enabled: false,
        runs: 200
      }
    }
  }
};

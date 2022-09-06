var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "legend chaos hotel fold kitten faculty melody slim virtual lava silver traffic";

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*" // Match any network id
    },
    rinkeby: {
      provider: function () {
        return new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/v3/d59c280b210b48feb6ea481068006751");
      },
      network_id: 4,
      gas: 6721975,
      gasPrice: 10000000000,
    }
  },
  compilers: {
    solc: {
      version: "0.6.0"
    }
  }
};

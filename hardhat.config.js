require("@nomiclabs/hardhat-waffle")
require("@nomiclabs/hardhat-etherscan")
require("hardhat-deploy")
require("dotenv").config()
require("hardhat-contract-sizer")

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const RINKEBY_ALCHEMY_URL = process.env.RINKEBYALCHEMYURL
const RINKEBY_PRIVATE_KEY = process.env.RINKEBY_PRIVATE_KEY
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY
const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
    solidity: "0.8.7",
    namedAccounts: {
        deployer: {
            default: 0, // here this will by default take the first account as deployer
            1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
        },
    },
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            chainId: 31337,
            blockConfirmations: 1,
        },
        rinkeby: {
            chainId: 4,
            blockConfirmations: 6,
            url: RINKEBY_ALCHEMY_URL,
            accounts: [RINKEBY_PRIVATE_KEY],
        },
    },
}

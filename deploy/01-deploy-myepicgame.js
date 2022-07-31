const { network } = require("hardhat")
const { networkConfig, developmentChains } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")

module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    const arguments = []
    const myEpicGame = await deploy("MyEpicGame", {
        from: deployer,
        args: arguments,
        log: true,
        waitConfirmation: network.config.blockConfirmations || 1,
    })

    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("Verifying contract...")
        await verify(myEpicGame, arguments)
    }
    log("-----------------------------------------------------")
}

module.exports.tags = ["all", "myEpicGame"]

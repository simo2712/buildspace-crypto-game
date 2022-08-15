const { frontEndContractsFile, frontEndAbiFile } = require("../helper-hardhat-config")
const fs = require("fs")
const { network } = require("hardhat")

module.exports = async () => {
    if (process.env.UPDATE_FRONT_END) {
        console.log("Writing to front end...")
        await updateContractAddresses()
        await updateAbi()
        console.log("Front end written!")
    }
}

async function updateAbi() {
    const myEpicGame = await ethers.getContract("MyEpicGame")
    fs.writeFileSync(frontEndAbiFile, myEpicGame.interface.format(ethers.utils.FormatTypes.json))
}

async function updateContractAddresses() {
    const myEpicGame = await ethers.getContract("MyEpicGame")
    console.log(frontEndContractsFile)
    const contractAddresses = JSON.parse(fs.readFileSync(frontEndContractsFile, "utf8"))
    if (network.config.chainId.toString() in contractAddresses) {
        if (!contractAddresses[network.config.chainId.toString()].includes(myEpicGame.address)) {
            contractAddresses[network.config.chainId.toString()].push(myEpicGame.address)
        }
    } else {
        contractAddresses[network.config.chainId.toString()] = [myEpicGame.address]
    }
    fs.writeFileSync(frontEndContractsFile, JSON.stringify(contractAddresses))
}
module.exports.tags = ["all", "frontend"]

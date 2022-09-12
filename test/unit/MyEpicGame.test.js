const { assert, expect } = require("chai")
const { network, deployments, ethers } = require("hardhat")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("MyEpicGame Unit Tests", function () {
          beforeEach(async function () {
              accounts = await ethers.getSigners()
              deployer = accounts[0]
              player1 = accounts[1]
              await deployments.fixture(["mocks", "gameEngine", "myEpicGame"])
              vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock")
              gameEngine = await ethers.getContract("GameEngine")
              myEpicGame = await ethers.getContract("MyEpicGame")
          })

          describe("MyEpicGame create characters", function () {
              it("Should create a new character", async function () {
                  const transaction = await myEpicGame.createCharacters(
                      ["Lautaro", "Lukaku", "Barella"], // Names
                      [
                          "https://www.fantamaster.it/wp-content/uploads/2022/05/lautaro-martinez_inter_esultanza_foto.jpg", // Images
                          "https://tmssl.akamaized.net/images/foto/galerie/romelu-lukaku-inter-mailand-1566880317-25036.jpg?lm=1566880330",
                          "https://www.raisport.rai.it/dl/img/2020/01/1600x900_1580333075135.barellaesulta.jpg",
                      ],
                      [250, 300, 200], // HP values
                      [100, 200, 75], // Attack damage values
                      [6, 3, 7], // Dexterity values
                      [6, 6, 6] // Luck values
                  )
                  const characterAttributes = await myEpicGame.getCharacterAttributes(1)
                  assert.equal(
                      characterAttributes.name,
                      "Lukaku",
                      "Character name should be Lukaku"
                  )
              })
          })
      })

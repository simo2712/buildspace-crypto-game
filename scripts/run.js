const { getNamedAccounts, deployments, network, ethers } = require("hardhat")

const main = async () => {
  const gameContractFactory = await hre.ethers.getContractFactory("MyEpicGame");
  const gameContract = await gameContractFactory.deploy();
  await gameContract.deployed();
  console.log(network.config.chainId);
  console.log("Contract deployed to:", gameContract.address);

  let txn;
  txn = await gameContract.createCharacters(
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
  );
  await txn.wait();

  txn = await gameContract.createCharacters(
    ["Brozovic", "Sanchez"],
    [
      "https://net-storage.tcccdn.com/storage/fcinternews.it/img_notizie/thumb3/c0/c0874e2a825c22638eceff09b96bca3d-95147-1c7efe366218a82fe280402e9d581ffc.jpeg",
      "https://c.tenor.com/AH2FzhsgSI0AAAAC/alexis-sanchez-i-campioni-sono-cos%C3%AC.gif",
    ],
    [200, 200],
    [75, 125],
    [6, 8],
    [6, 6]
  );
  await txn.wait();

  txn = await gameContract.createBosses(
    ["Padre Pioli"], // Boss name
    ["https://papavanbasten.com/wp-content/uploads/2019/12/padre-pioli.jpg"], // Boss image
    [20], // Boss hp
    [50], // Boss attack damage
    [12000] // Boss reward
  );
  await txn.wait();

  // We only have three characters.
  // an NFT w/ the character at index 2 of our array.
  //txn = await gameContract.mintCharacterNFT(1);
  //await txn.wait();

  //txn = await gameContract.attackBoss();
  //await txn.wait();
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();

const main = async () => {
  const gameContractFactory = await hre.ethers.getContractFactory("MyEpicGame");
  const gameContract = await gameContractFactory.deploy(
    ["Lautaro", "Lukaku", "Barella"], // Names
    [
      "https://www.fantamaster.it/wp-content/uploads/2022/05/lautaro-martinez_inter_esultanza_foto.jpg", // Images
      "https://tmssl.akamaized.net/images/foto/galerie/romelu-lukaku-inter-mailand-1566880317-25036.jpg?lm=1566880330",
      "https://www.raisport.rai.it/dl/img/2020/01/1600x900_1580333075135.barellaesulta.jpg",
    ],
    [250, 300, 200], // HP values
    [100, 100, 75], // Attack damage values
    [8, 9, 5], // Strenght values
    [6, 3, 7], // Dexterity values
    [4, 5, 6], // Intelligence values
    [7, 8, 7], // Vitality values
    [6, 6, 6], // Luck values
    "Padre Pioli", // Boss name
    "https://papavanbasten.com/wp-content/uploads/2019/12/padre-pioli.jpg", // Boss image
    20, // Boss hp
    50, // Boss attack damage
    12000 // Boss reward
  );
  await gameContract.deployed();
  console.log("Contract deployed to:", gameContract.address);

  let txn;
  // We only have three characters.
  // an NFT w/ the character at index 2 of our array.
  txn = await gameContract.mintCharacterNFT(1);
  await txn.wait();

  txn = await gameContract.attackBoss();
  await txn.wait();
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

const main = async () => {
  const gameContractFactory = await hre.ethers.getContractFactory("MyEpicGame");
  const gameContract = await gameContractFactory.deploy(
    ["Lautaro", "Lukaku", "Dybala"], // Names
    [
      "https://www.fantamaster.it/wp-content/uploads/2022/05/lautaro-martinez_inter_esultanza_foto.jpg", // Images
      "https://tmssl.akamaized.net/images/foto/galerie/romelu-lukaku-inter-mailand-1566880317-25036.jpg?lm=1566880330",
      "https://cdn.corrieredellosport.it/img/990/495/2022/07/10/094858039-b40c1b0d-bbe1-41a3-af53-9b2ca59ea5b7.jpg",
    ],
    [300, 200, 250], // HP values
    [70, 100, 75], // Attack damage values
    "Padre Pioli", // Boss name
    "https://papavanbasten.com/wp-content/uploads/2019/12/padre-pioli.jpg", // Boss image
    10000, // Boss hp
    50 // Boss attack damage
  );

  await gameContract.deployed();
  console.log("Contract deployed to:", gameContract.address);
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

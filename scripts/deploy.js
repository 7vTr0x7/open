

const { ethers, upgrades } = require('hardhat');

async function main () {
  const TokenizedShares = await hre.ethers.deployContract('TokenizedShares');
  console.log('Deploying TokenizedShares...');
  await TokenizedShares.waitForDeployment();
  console.log('tokenizedShares deployed to:', TokenizedShares.target);

//   const TokenizedShares = await ethers.getContractFactory('TokenizedShares');
//   console.log('Upgrading TokenizedShares...');
//   await upgrades.upgradeProxy('0xD02c15940D1aDd2A48615460E430565B62680D88', TokenizedShares);
//   console.log('TokenizedShares upgraded');

}

  // // Upgrading
  // const BoxV2 = await ethers.getContractFactory("BoxV2");
  // const upgraded = await upgrades.upgradeProxy(await instance.getAddress(), BoxV2);



// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

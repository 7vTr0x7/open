const  hre  = require("hardhat");


async function main () {
  const CPAMM = await hre.ethers.deployContract('CPAMM',["0xD6238E48e9C5cc13cF499dc6B3dcf35706f90b7d"]);
  console.log('Deploying CPAMM...');
  await CPAMM.waitForDeployment();
  console.log('CPAMM deployed to:', CPAMM.target);
  
  // const CPAMM = await ethers.getContractFactory('CPAMM');
  // console.log('Upgrading CPAMM...');
  // await upgrades.upgradeProxy('0xC5bDdBfe1268278Bf066d82702E8CF9BE140310E', CPAMM);
  // console.log('TokenizedShares upgraded');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });


  //0x2cC4217f156ec4A902f9DF538E8caE7ea1a8d39b
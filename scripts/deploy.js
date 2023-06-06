const hre = require('hardhat');

const main = async () => {
    const BlockJuice = await hre.ethers.getContractFactory('BlockJuice');
    const BlockJuiceContract = await BlockJuice.deploy(1234);
    await BlockJuiceContract.deployed();

    console.log('Address:', BlockJuiceContract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

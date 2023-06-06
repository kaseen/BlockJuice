const hre = require('hardhat');

const main = async () => {
    const contractAddress = '0x9B57f8D5d79b0b79A8e0599A0de33ff7C851C399';
    const BlockJuiceContract = await hre.ethers.getContractAt('BlockJuice', contractAddress);

    const price = await BlockJuiceContract.getLatestData();
    console.log('Price:', price);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

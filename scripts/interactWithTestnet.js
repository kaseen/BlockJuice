const hre = require('hardhat');

const main = async () => {
    const contractAddress = '0xA6179BEEFDc35932D688468f1551364D8Aa0996a';
    const BlockJuiceContract = await hre.ethers.getContractAt('BlockJuice', contractAddress);

    const price = await BlockJuiceContract.getLatestData();
    console.log('Price:', price);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

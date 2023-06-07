const hre = require('hardhat');

const main = async () => {
    const [owner] = await ethers.getSigners();

    const contractAddress = '0xc451fEf94d61c9472A285A3E9a3327654d950Cca';
    const BlockJuiceContract = await hre.ethers.getContractAt('BlockJuice', contractAddress);

    const price = await BlockJuiceContract.getLatestData();
    console.log('Price:', price);

    const MERCHANT_ROLE = await BlockJuiceContract.MERCHANT_ROLE();
    await BlockJuiceContract.grantRole(MERCHANT_ROLE, owner.address);

    await BlockJuiceContract.registerProduct(3000, 10, '');
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

const hre = require('hardhat');

const main = async () => {
    const BlockJuice = await hre.ethers.getContractFactory('BlockJuice');
    const BlockJuiceContract = await BlockJuice.deploy(1234, '0x694AA1769357215DE4FAC081bf1f309aDC325306');
    await BlockJuiceContract.deployed();

    console.log('Address:', BlockJuiceContract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

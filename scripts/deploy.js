const hre = require('hardhat');
const fs = require('fs');

const main = async () => {

    const BlockJuice = await hre.ethers.getContractFactory('BlockJuice');
    const BlockJuiceContract = await BlockJuice.deploy(1234, '0x694AA1769357215DE4FAC081bf1f309aDC325306');
    await BlockJuiceContract.deployed();

    const rawData = JSON.parse(fs.readFileSync('./artifacts/contracts/BlockJuice.sol/BlockJuice.json', 'utf8'));
    const res = JSON.stringify({ address: BlockJuiceContract.address, abi: rawData.abi });
    fs.writeFileSync('./frontend.json', res);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

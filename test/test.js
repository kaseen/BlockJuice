const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require('chai');

describe('BlockJuice', () => {

    const setupFixture = async() => {
        const [owner, alt1, alt2] = await hre.ethers.getSigners();

        const BlockJuice = await hre.ethers.getContractFactory('BlockJuice');
        const BlockJuiceContract = await BlockJuice.deploy();
        await BlockJuiceContract.deployed();

        // Mint dummy products(for testing purpose)
        await BlockJuiceContract.registerProduct(3000, ethers.utils.parseUnits('0.1'));
        const DUMMY_ID = 0;

        /*
        console.log(owner.address)
        console.log(alt1.address)
        console.log(alt2.address)
        */

        return { BlockJuiceContract, owner, alt1, alt2, DUMMY_ID };
    }

    describe('Test', () => {
        it('Should add new product', async () => {
            const { BlockJuiceContract, alt1, DUMMY_ID } = await loadFixture(setupFixture);

            // TODO: Revert if role is not set
            const amount = 3000;
            const price = ethers.utils.parseUnits('0.1');
            await expect(BlockJuiceContract.connect(alt1).registerProduct(amount, price))
                .to.emit(BlockJuiceContract, 'TransferSingle').withArgs(alt1.address, ethers.constants.AddressZero, alt1.address, DUMMY_ID + 1, amount)
                .to.emit(BlockJuiceContract, 'ProductRegistered').withArgs(DUMMY_ID + 1, amount, price);
        });

        it('Should buy product', async () => {
            const { BlockJuiceContract, owner, alt2, DUMMY_ID } = await loadFixture(setupFixture);

            const amount = 10;

            await expect(BlockJuiceContract.connect(alt2).buyProduct(DUMMY_ID, amount, { value: ethers.utils.parseUnits('0.1') }))
                .to.revertedWithCustomError(BlockJuiceContract, 'InvalidFunds');

            await expect(BlockJuiceContract.connect(alt2).buyProduct(DUMMY_ID, amount, { value: ethers.utils.parseUnits('1') }))
                .to.emit(BlockJuiceContract, 'TransferSingle').withArgs(alt2.address, owner.address, alt2.address, DUMMY_ID, amount)
                .to.emit(BlockJuiceContract, 'ProductBought');
        });
    });

});
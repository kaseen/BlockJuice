const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');
const { expect } = require('chai');

describe('BlockJuice', () => {

    const setupFixture = async () => {
        const [owner, alt1, alt2] = await hre.ethers.getSigners();

        const BlockJuice = await hre.ethers.getContractFactory('BlockJuice');
        const BlockJuiceContract = await BlockJuice.deploy(1234);  // fee is 12.34%
        await BlockJuiceContract.deployed();

        const MERCHANT_ROLE = await BlockJuiceContract.MERCHANT_ROLE();
        await BlockJuiceContract.grantRole(MERCHANT_ROLE, owner.address);

        // Mint dummy products(for testing purpose)
        await BlockJuiceContract.registerProduct(3000, ethers.utils.parseUnits('0.1'));
        await BlockJuiceContract.registerProduct(10, ethers.utils.parseUnits('0.3'));
        await BlockJuiceContract.registerProduct(50, ethers.utils.parseUnits('0.2'));
        const DUMMY_PRODUCT_ID = 0;

        return { BlockJuiceContract, owner, alt1, alt2, DUMMY_PRODUCT_ID, MERCHANT_ROLE };
    }

    describe('Test', () => {
        it('Should grant MERCHANT_ROLE and add new product', async () => {
            const { BlockJuiceContract, alt1, DUMMY_PRODUCT_ID, MERCHANT_ROLE } = await loadFixture(setupFixture);
            const amount = 3000;
            const price = ethers.utils.parseUnits('0.1');

            // Revert if MERCHANT_ROLE is not set
            await expect(BlockJuiceContract.connect(alt1).registerProduct(amount, price))
                .to.revertedWithCustomError(BlockJuiceContract, 'UnauthorizedAccess');

            // Grant role
            await BlockJuiceContract.grantRole(MERCHANT_ROLE, alt1.address);

            await expect(BlockJuiceContract.connect(alt1).registerProduct(amount, price))
                .to.emit(BlockJuiceContract, 'TransferSingle').withArgs(alt1.address, ethers.constants.AddressZero, alt1.address, DUMMY_PRODUCT_ID + 3, amount)
                .to.emit(BlockJuiceContract, 'ProductRegistered').withArgs(DUMMY_PRODUCT_ID + 3, amount, price);
        });

        it('Should test buyProduct function', async () => {
            const { BlockJuiceContract, owner, alt2, DUMMY_PRODUCT_ID } = await loadFixture(setupFixture);
            const amount = 10;

            await expect(BlockJuiceContract.connect(alt2).buyProduct(DUMMY_PRODUCT_ID, amount, { value: ethers.utils.parseUnits('0.1') }))
                .to.revertedWithCustomError(BlockJuiceContract, 'InvalidFunds');

            await expect(BlockJuiceContract.connect(alt2).buyProduct(DUMMY_PRODUCT_ID, amount, { value: ethers.utils.parseUnits('1') }))
                .to.emit(BlockJuiceContract, 'TransferSingle').withArgs(alt2.address, owner.address, ethers.constants.AddressZero, DUMMY_PRODUCT_ID, amount)
                //.to.emit(BlockJuiceContract, 'TransferSingle').withArgs(alt2.address, owner.address, alt2.address, DUMMY_PRODUCT_ID, amount)
                .to.emit(BlockJuiceContract, 'ProductBought');
        });

        it('Should test buyProductBatch function', async () => {
            const { BlockJuiceContract, alt2 } = await loadFixture(setupFixture);

            await expect(BlockJuiceContract.connect(alt2).buyProductBatch([0, 1, 2], [10, 10], { value: ethers.utils.parseUnits('10') }))
                .to.revertedWithCustomError(BlockJuiceContract, 'InvalidQuery'); 

            await expect(BlockJuiceContract.connect(alt2).buyProductBatch([0, 1, 3], [10, 10, 10], { value: ethers.utils.parseUnits('10') }))
                .to.revertedWithCustomError(BlockJuiceContract, 'InvalidProductID');

            await expect(BlockJuiceContract.connect(alt2).buyProductBatch([0, 1, 2], [10, 10, 10], { value: ethers.utils.parseUnits('1') }))
                .to.revertedWithCustomError(BlockJuiceContract, 'InvalidFunds');

            await expect(BlockJuiceContract.connect(alt2).buyProductBatch([0, 1, 2], [10, 10, 10], { value: ethers.utils.parseUnits('10') }))
                .to.emit(BlockJuiceContract, 'ProductsBought').withArgs([0, 1, 2], [10, 10, 10], alt2.address);

            await BlockJuiceContract.connect(alt2).buyProductBatch([0, 1, 2], [6, 9, 8], { value: ethers.utils.parseUnits('10') })
        });

        it('Should refill product amount', async () => {
            const { BlockJuiceContract, owner, alt1, DUMMY_PRODUCT_ID } = await loadFixture(setupFixture);
            const amount = 100;

            // Alt1 is not owner of product expect revert
            await expect(BlockJuiceContract.connect(alt1).refillProductAmount(DUMMY_PRODUCT_ID, amount))
                .to.revertedWithCustomError(BlockJuiceContract, 'UnauthorizedAccess');

            const beforeRefill = await BlockJuiceContract.balanceOf(owner.address, DUMMY_PRODUCT_ID);
            await expect(BlockJuiceContract.refillProductAmount(DUMMY_PRODUCT_ID, amount))
                .to.emit(BlockJuiceContract, 'TransferSingle').withArgs(owner.address, ethers.constants.AddressZero, owner.address, DUMMY_PRODUCT_ID, amount)
                .to.emit(BlockJuiceContract, 'ProductRefilled').withArgs(DUMMY_PRODUCT_ID, amount);

            const afterRefill = await BlockJuiceContract.balanceOf(owner.address, DUMMY_PRODUCT_ID);
            expect(afterRefill.eq(beforeRefill.add(amount))).to.be.equal(true);
        });

        it('Should withdraw merchant balance', async () => {
            const { BlockJuiceContract } = await loadFixture(setupFixture);

        });
    });
});
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');
const { expect } = require('chai');

describe('BlockJuice', () => {

    const setupFixture = async () => {
        const [owner, testUser, testMerchant, notMerchant] = await hre.ethers.getSigners();

        const BlockJuice = await hre.ethers.getContractFactory('BlockJuice');
        const BlockJuiceContract = await BlockJuice.deploy(1234);  // fee is 12.34%
        await BlockJuiceContract.deployed();

        const MERCHANT_ROLE = await BlockJuiceContract.MERCHANT_ROLE();
        await BlockJuiceContract.grantRole(MERCHANT_ROLE, owner.address);
        await BlockJuiceContract.grantRole(MERCHANT_ROLE, testMerchant.address);

        // Mint dummy products(for testing purpose)
        await BlockJuiceContract.connect(testMerchant).registerProduct(3000, ethers.utils.parseUnits('0.1'));
        await BlockJuiceContract.connect(testMerchant).registerProduct(10, ethers.utils.parseUnits('0.3'));
        await BlockJuiceContract.connect(testMerchant).registerProduct(50, ethers.utils.parseUnits('0.2'));
        const DUMMY_PRODUCT_ID = 0;

        return { BlockJuiceContract, owner, testUser, testMerchant, notMerchant, DUMMY_PRODUCT_ID, MERCHANT_ROLE };
    }

    describe('Test', () => {
        it('Should grant MERCHANT_ROLE and add new product', async () => {
            const { BlockJuiceContract, notMerchant, DUMMY_PRODUCT_ID, MERCHANT_ROLE } = await loadFixture(setupFixture);
            const amount = 3000;
            const price = ethers.utils.parseUnits('0.1');

            // Revert if MERCHANT_ROLE is not set
            await expect(BlockJuiceContract.connect(notMerchant).registerProduct(amount, price))
                .to.revertedWithCustomError(BlockJuiceContract, 'UnauthorizedAccess');

            // Grant role
            await BlockJuiceContract.grantRole(MERCHANT_ROLE, notMerchant.address);

            await expect(BlockJuiceContract.connect(notMerchant).registerProduct(amount, price))
                .to.emit(BlockJuiceContract, 'TransferSingle').withArgs(notMerchant.address, ethers.constants.AddressZero, notMerchant.address, DUMMY_PRODUCT_ID + 3, amount)
                .to.emit(BlockJuiceContract, 'ProductRegistered').withArgs(DUMMY_PRODUCT_ID + 3, amount, price);
        });

        it('Should test buyProduct function', async () => {
            const { BlockJuiceContract, testMerchant, testUser, DUMMY_PRODUCT_ID } = await loadFixture(setupFixture);
            const amount = 10;

            await expect(BlockJuiceContract.connect(testUser).buyProduct(DUMMY_PRODUCT_ID, amount, { value: ethers.utils.parseUnits('0.1') }))
                .to.revertedWithCustomError(BlockJuiceContract, 'InvalidFunds');

            await expect(BlockJuiceContract.connect(testUser).buyProduct(DUMMY_PRODUCT_ID, amount, { value: ethers.utils.parseUnits('1') }))
                .to.emit(BlockJuiceContract, 'TransferSingle').withArgs(testUser.address, testMerchant.address, ethers.constants.AddressZero, DUMMY_PRODUCT_ID, amount)
                //.to.emit(BlockJuiceContract, 'TransferSingle').withArgs(testUser.address, testMerchant.address, testUser.address, DUMMY_PRODUCT_ID, amount)
                .to.emit(BlockJuiceContract, 'ProductBought').withArgs(DUMMY_PRODUCT_ID, amount, testUser.address);
        });

        it('Should test buyProductBatch function', async () => {
            const { BlockJuiceContract, testUser } = await loadFixture(setupFixture);

            await expect(BlockJuiceContract.connect(testUser).buyProductBatch([0, 1, 2], [10, 10], { value: ethers.utils.parseUnits('10') }))
                .to.revertedWithCustomError(BlockJuiceContract, 'InvalidQuery'); 

            await expect(BlockJuiceContract.connect(testUser).buyProductBatch([0, 1, 3], [10, 10, 10], { value: ethers.utils.parseUnits('10') }))
                .to.revertedWithCustomError(BlockJuiceContract, 'InvalidProductID');

            await expect(BlockJuiceContract.connect(testUser).buyProductBatch([0, 1, 2], [10, 10, 10], { value: ethers.utils.parseUnits('1') }))
                .to.revertedWithCustomError(BlockJuiceContract, 'InvalidFunds');

            await expect(BlockJuiceContract.connect(testUser).buyProductBatch([0, 1, 2], [10, 10, 10], { value: ethers.utils.parseUnits('10') }))
                .to.emit(BlockJuiceContract, 'ProductsBought').withArgs([0, 1, 2], [10, 10, 10], testUser.address);
        });

        it('Should refill product amount', async () => {
            const { BlockJuiceContract, testMerchant, notMerchant, DUMMY_PRODUCT_ID } = await loadFixture(setupFixture);
            const amount = 100;

            // notMerchant is not owner of product expect revert
            await expect(BlockJuiceContract.connect(notMerchant).refillProductAmount(DUMMY_PRODUCT_ID, amount))
                .to.revertedWithCustomError(BlockJuiceContract, 'UnauthorizedAccess');

            const beforeRefill = await BlockJuiceContract.balanceOf(testMerchant.address, DUMMY_PRODUCT_ID);
            await expect(BlockJuiceContract.connect(testMerchant).refillProductAmount(DUMMY_PRODUCT_ID, amount))
                .to.emit(BlockJuiceContract, 'TransferSingle').withArgs(testMerchant.address, ethers.constants.AddressZero, testMerchant.address, DUMMY_PRODUCT_ID, amount)
                .to.emit(BlockJuiceContract, 'ProductRefilled').withArgs(DUMMY_PRODUCT_ID, amount);

            const afterRefill = await BlockJuiceContract.balanceOf(testMerchant.address, DUMMY_PRODUCT_ID);
            expect(afterRefill.eq(beforeRefill.add(amount))).to.be.equal(true);
        });

        it('Should test functions with withdrawal', async () => {
            const { BlockJuiceContract, owner, testUser, testMerchant, DUMMY_PRODUCT_ID } = await loadFixture(setupFixture);

            const amount = 10;
            const value = ethers.utils.parseUnits('1');

            await BlockJuiceContract.connect(testUser).buyProduct(DUMMY_PRODUCT_ID, 10, { value: ethers.utils.parseUnits('1') });

            await expect(BlockJuiceContract.ownerWithdraw())
                .to.emit(BlockJuiceContract, 'FundsWithdrawn').withArgs(owner.address);

            await expect(BlockJuiceContract.connect(testMerchant).merchantWithdraw())
                .to.emit(BlockJuiceContract, 'FundsWithdrawn').withArgs(testMerchant.address);
        });
    });
});
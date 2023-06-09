// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IBlockJuice {

    /**
     *  Struct about info of a product
     */
    struct ProductInfo {
        address productOwner;
        uint256 priceInDollars;
        string productUri;
    }

    /**
     *  Emited when product is registered on platform
     */
    event ProductRegistered(uint256 productId, uint256 amount, uint256 value);

    /**
     *  Emited when product is bought on platform
     */
    event ProductBought(uint256 productId, uint256 amount, address buyer);

    /**
     *  Emited when multiple products are bought on platform
     */
    event ProductsBought(uint256[] ids, uint256[] amounts, address buyer);

    /**
     *  Emited when product is bought on platform
     */
    event ProductRefilled(uint256 productId, uint256 amount);

    /**
     *  Emited when price of product price with given id is changed
     */
    event ProductPriceChanged(uint256 productId, uint256 newPrice);

    /**
     *  Emited when merchant or owner withdraws funds
     */
    event FundsWithdrawn(address user);

    /**
     *  Emited when owner of BlockJuice is changed
     */
    event OwnerChanged(address newOwner);

    /**
     *  Emited when address of chainlink data feed is changed
     */
    event DataFeedAddressChanged(address newAddress);

    /**
     *  Emited when user wins lottery
     */
    event LotteryWon(address user, uint256 productId);

    /**
     *  Thrown when product id does not exists
     */
    error InvalidProductID();

    /**
     *  Thrown when msg.value is less than product value
     */
    error InvalidFunds();

    /**
     *  Thrown when msg.sender have unauthorized access
     */
    error UnauthorizedAccess();

    /**
     *  Thrown when lengths of arrays in batch buying are not the same 
     */
    error InvalidQuery();
}
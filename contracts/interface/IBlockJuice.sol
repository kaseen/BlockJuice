// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IBlockJuice {

    /*
    *   Struct about info of a product
    */
    struct ProductInfo {
        address productOwner;
        uint256 price;
    }

    /*
    *   Emited when product is registered on platform
    */
    event ProductRegistered(uint256 id, uint256 amount, uint256 value);

    /*
    *   Emited when product is bought on platform
    */
    event ProductBought(uint256 id, uint256 amount, address buyer);

    /*
    *   Thrown when product id does not exists
    */
    error InvalidProductID();

    /*
    *   Thrown when msg.value is less than product value
    */
    error InvalidFunds();
}
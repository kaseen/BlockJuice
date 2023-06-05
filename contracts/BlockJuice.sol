// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import './interface/IBlockJuice.sol';

// TODO: Is AccessControl
// TODO: EUR TO CRYPTO PRICES CHAINLINK

contract BlockJuice is ERC1155, IBlockJuice {

    // Mapping id to price
    mapping(uint256 => ProductInfo) public productInfo;

    uint256 private idOfNextProduct;

    constructor() ERC1155('TODO'){
        idOfNextProduct = 0;
    }

    // TODO: only specific role
    function registerProduct(uint256 amount, uint256 price) public {
        // require 
        _mint(msg.sender, idOfNextProduct, amount, '');
        productInfo[idOfNextProduct].productOwner = msg.sender;
        productInfo[idOfNextProduct].price = price;
        emit ProductRegistered(idOfNextProduct, amount, price);
        idOfNextProduct++;
    }

    // TODO: buyProductBatch
    function buyProduct(uint256 id, uint256 amount) public payable {
        if(productInfo[id].price * amount > msg.value)
            revert InvalidFunds();
        if(id > idOfNextProduct) 
            revert InvalidProductID();
        
        // TODO: Inspect (does transfer needs approval?)
        _safeTransferFrom(productInfo[id].productOwner, msg.sender, id, amount, '');
        emit ProductBought(id, amount, msg.sender);
    }

}
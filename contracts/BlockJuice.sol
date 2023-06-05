// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import './interface/IBlockJuice.sol';

// TODO: EUR TO CRYPTO PRICES CHAINLINK
// TODO: Platform fee
// TODO: Burn kad se transfer
contract BlockJuice is ERC1155, AccessControl, IBlockJuice {

    bytes32 public constant MERCHANT_ROLE = keccak256('MERCHANT_ROLE');

    // Mapping id to price
    mapping(uint256 => ProductInfo) public productInfo;

    uint256 private idOfNextProduct;

    constructor() ERC1155('TODO'){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        idOfNextProduct = 0;
    }

    function registerProduct(uint256 amount, uint256 price) public {
        if(!hasRole(MERCHANT_ROLE, msg.sender))
            revert UnauthorizedAccess();
        
        productInfo[idOfNextProduct].productOwner = msg.sender;
        productInfo[idOfNextProduct].price = price;
        _mint(msg.sender, idOfNextProduct, amount, '');
        
        emit ProductRegistered(idOfNextProduct, amount, price);
        idOfNextProduct++;
    }

    function refillProductAmount(uint256 productId, uint256 amount) public {
        if(productInfo[productId].productOwner != msg.sender)
            revert UnauthorizedAccess();
        
        _mint(msg.sender, productId, amount, '');
        emit ProductRefilled(productId, amount);
    }

    // TODO: buyProductBatch
    function buyProduct(uint256 productId, uint256 amount) public payable {
        if(productInfo[productId].price * amount > msg.value)
            revert InvalidFunds();
        if(productId > idOfNextProduct) 
            revert InvalidProductID();
        
        // TODO: Inspect (does transfer needs approval?)
        _safeTransferFrom(productInfo[productId].productOwner, msg.sender, productId, amount, '');
        emit ProductBought(productId, amount, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import './interface/IBlockJuice.sol';

import 'hardhat/console.sol';

// TODO: EUR TO CRYPTO PRICES CHAINLINK
// TODO: fallback function
// TODO: Fee on buyProductBatch
contract BlockJuice is ERC1155, AccessControl, IBlockJuice {

    bytes32 public constant MERCHANT_ROLE = keccak256('MERCHANT_ROLE');

    // Mapping id to product info
    mapping(uint256 => ProductInfo) public productInfo;

    // Mapping merchant addresses to their balances
    mapping(address => uint256) private merchantBalances;

    uint256 private idOfNextProduct;
    uint256 private ownerBalance;
    uint256 private platformFee;

    constructor(uint256 _platfromFee) ERC1155('TODO'){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        idOfNextProduct = 0;
        platformFee = _platfromFee;
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

    function buyProduct(uint256 productId, uint256 amount) public payable {
        if(productInfo[productId].price * amount > msg.value)
            revert InvalidFunds();
        if(productId >= idOfNextProduct) 
            revert InvalidProductID();

        address productOwner = productInfo[productId].productOwner;

        // Calculate fee and split balances
        uint256 feeCalculated = (msg.value * platformFee) / 10000;
        merchantBalances[productOwner] += msg.value - feeCalculated;
        ownerBalance += feeCalculated;
        
        // TODO: Before: burn _safeTransferFrom(productInfo[productId].productOwner, msg.sender, productId, amount, '');
        _burn(productOwner, productId, amount);
        emit ProductBought(productId, amount, msg.sender);
    }

    function buyProductBatch(uint256[] memory productIds, uint256[] memory amounts) public payable {
        if(productIds.length != amounts.length)
            revert InvalidQuery();

        uint256 totalCost = 0;
        for(uint256 i; i < productIds.length; ++i){
            uint256 productId = productIds[i];
            if(productId >= idOfNextProduct) 
                revert InvalidProductID();
            totalCost += productInfo[productId].price * amounts[i];
            _burn(productInfo[productId].productOwner, productId, amounts[i]);
        }

        if(totalCost > msg.value)
            revert InvalidFunds();

        emit ProductsBought(productIds, amounts, msg.sender);
    }
    
    function merchantWithdraw() public payable {
        if(merchantBalances[msg.sender] == 0)
            revert InvalidFunds();

        uint256 tmp = merchantBalances[msg.sender];
        merchantBalances[msg.sender] = 0;

        payable(msg.sender).transfer(tmp);
        emit FundsWithdrawn(msg.sender);
    }

    function ownerWithdraw() public payable {
        if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender))
            revert UnauthorizedAccess();

        if(ownerBalance == 0)
            revert InvalidFunds();

        uint256 tmp = ownerBalance;
        ownerBalance = 0;

        payable(msg.sender).transfer(tmp);
        emit FundsWithdrawn(msg.sender); 
    }

    function transferOwnership(address newOwner) public {
        if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender))
            revert UnauthorizedAccess();

        grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);

        emit OwnerChanged(newOwner);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
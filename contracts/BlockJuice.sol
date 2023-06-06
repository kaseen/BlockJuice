// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import './interface/IBlockJuice.sol';

import 'hardhat/console.sol';

// TODO: fallback function
// TODO: Fee on buyProductBatch
// TODO: Merchant can change product price
contract BlockJuice is ERC1155, AccessControl, IBlockJuice {

    bytes32 public constant MERCHANT_ROLE = keccak256('MERCHANT_ROLE');

    // Mapping id to product info
    mapping(uint256 => ProductInfo) public productInfo;

    // Mapping merchant addresses to their balances
    mapping(address => uint256) private merchantBalances;

    // Chainlink interface for using data feeds
    AggregatorV3Interface private dataFeed;

    uint256 private idOfNextProduct;
    uint256 private ownerBalance;
    uint256 private platformFee;

    constructor(uint256 _platfromFee) ERC1155('TODO'){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        dataFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
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
        if(convertDollarToPriceInCrypto(productId) * amount != msg.value)
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

    function convertDollarToPriceInCrypto(uint256 productId) public view returns (uint256) {
        //(,int price,,,) = dataFeed.latestRoundData(); TODO
        int256 price = 180000000000; // hardcoded value ($1800) for local testing
        uint256 adjustedPrice = uint256(price) * 10 ** 10;
        uint256 priceInUsd = productInfo[productId].price * (10 ** 18);
        uint256 priceInCrypto = (priceInUsd * 10 ** 18) / adjustedPrice;

        return priceInCrypto;
    }

    /**
     *      Authentication methods
     */
    
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

    function setDataFeedAddress(address newAddress) public {
        if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender))
            revert UnauthorizedAccess();

        dataFeed = AggregatorV3Interface(newAddress);
        emit DataFeedAddressChanged(newAddress);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
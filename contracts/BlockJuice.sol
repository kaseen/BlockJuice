// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import './interface/IBlockJuice.sol';

import 'hardhat/console.sol';

// TODO: Different fee for each product
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

    constructor(uint256 _platfromFee, address chainlinkPriceFeedAddress) ERC1155('TODO'){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        dataFeed = AggregatorV3Interface(chainlinkPriceFeedAddress);
        idOfNextProduct = 0;
        platformFee = _platfromFee;
    }

    function buyProduct(uint256 productId, uint256 amount) public payable {
        if(calculatePriceInEth(productInfo[productId].priceInDollars, getLatestData()) * amount != msg.value)
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
        int256 ethPrice = getLatestData();
        uint256 n = productIds.length;

        for(uint256 i; i < n; ++i){
            uint256 productId = productIds[i];

            if(productId >= idOfNextProduct) 
                revert InvalidProductID();

            uint256 currentPrice = calculatePriceInEth(productInfo[productId].priceInDollars, ethPrice) * amounts[i];
            totalCost += currentPrice;

            // Fee splitting between merchant and owner (TODO: For different products different fee calculation)
            uint256 feeCalculated = (currentPrice * platformFee) / 10000;
            merchantBalances[productInfo[productId].productOwner] += currentPrice - feeCalculated;
            ownerBalance += feeCalculated;

            _burn(productInfo[productId].productOwner, productId, amounts[i]);
        }

        if(totalCost != msg.value)
            revert InvalidFunds();

        emit ProductsBought(productIds, amounts, msg.sender);
    }

    function getLatestData() public view returns (int) {
        //(,int price,,,) = dataFeed.latestRoundData(); TODO
        int256 price = 180000000000; // hardcoded value ($1800) for local testing
        return price;
    }

    function calculatePriceInEth(uint256 dollarAmount, int256 ethPrice) private pure returns (uint256) {
        uint256 adjustedEthPrice = uint256(ethPrice) * 10 ** 10;
        uint256 priceInUsd = dollarAmount * (10 ** 18);
        uint256 priceInCrypto = (priceInUsd * 10 ** 18) / adjustedEthPrice;

        return priceInCrypto;
    }

    /**
     *      Authentication functions for merchants
     */

    function registerProduct(uint256 amount, uint256 price) public {
        if(!hasRole(MERCHANT_ROLE, msg.sender))
            revert UnauthorizedAccess();
        
        productInfo[idOfNextProduct].productOwner = msg.sender;
        productInfo[idOfNextProduct].priceInDollars = price;
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

    function merchantChangePrice(uint256 productId, uint256 newPrice) public {
        if(productInfo[productId].productOwner != msg.sender)
            revert UnauthorizedAccess();

        productInfo[productId].priceInDollars = newPrice;
        emit ProductPriceChanged(productId, newPrice);
    }
    
    function merchantWithdraw() public payable {
        if(merchantBalances[msg.sender] == 0)
            revert InvalidFunds();

        uint256 tmp = merchantBalances[msg.sender];
        merchantBalances[msg.sender] = 0;

        payable(msg.sender).transfer(tmp);
        emit FundsWithdrawn(msg.sender);
    }

    /**
     *      Authentication functions for owner
     */

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
# Block Juice

Experience the future of purchasing fresh homemade juices with cryptocurrency through Block Juice. Whether you prefer our convenient vending machines or our user-friendly app, our platform seamlessly combines physical and virtual sales. Powered by Ethereum and Metamask, we offer a secure and decentralized system for transactions. Scan a QR code to transfer crypto to the vendor's wallet. Engage in optional features like giving tips, playing slot machine games for extra rewards, and participating in lotteries. Our SPV platform fosters crypto use and market development. Stay tuned for app delivery options and the integration of NFTs. Imagine our vending machines in high-traffic areas, expanding their reach and impact. Embrace the Web3 revolution with Block Juice!

## Features (implemented for now):
- Buying multiple products in single transaction
- Using Chainlink Data Feeds to convert product price to price in crypto
- Role-based access control mechanisms with OpenZeppelin's [AccessControl](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol). This allows only merchants to register new products and to transfer ownership if project is sold
- Fee system (with 2 decimals) for splitting funds between merchant and owner of smart contract
- Lottery based on tipping when buying single product for chance to get double rewards for the price of one

## Installation
Block Juice requires [Node.js](https://nodejs.org/) v18+ to run

Install the dependencies with:
```shell
yarn install
```

To deploy to Sepolia testnet run the following script:
```shell
yarn hardhat run scripts/deploy.js --network sepolia
```

Address (and abi) of deployed contract will be saved in file frontend.json.

To run tests on local Ethereum network (built-in with Hardhat) run following script:
```shell
yarn hardhat test
```
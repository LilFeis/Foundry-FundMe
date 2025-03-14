// SPDX-License-Identifier: MIT

// Deploy mocks when we are on a local anvil chain
// Keep track of contrasct adressess across diferent chainsç
// SEPOLIA USD/ETH
// Mainnet ETH/USD

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    //If whe are on a local blockchain, we will use the mock
    //If we are on a testnet, we will use the testnet address (otherwise , grab the existing adress on the live network)
    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_ANSWER = 2000e8;


    struct NetworkConfig {
        address pricefeed;
    }

    constructor () {
        if (block.chainid == 11155111) activeNetworkConfig = getSepoliaEthConfig();
        else if (block.chainid == 1) activeNetworkConfig = getMainnetConfig();
        else activeNetworkConfig = getOrCreateAnvilEthConfig();
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        //price feed address
        NetworkConfig memory sepoliaConfig = NetworkConfig({pricefeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
        return sepoliaConfig;
    }

    function getMainnetConfig() public pure returns (NetworkConfig memory) {
        //price feed address
        NetworkConfig memory ethConfig = NetworkConfig({pricefeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419});
        return ethConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.pricefeed != address(0)) return activeNetworkConfig;

        //price feed address
        //Deploy the mocks
        //Retrun the mock address

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_ANSWER);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({pricefeed: address(mockPriceFeed)});
        return anvilConfig;
    }
}
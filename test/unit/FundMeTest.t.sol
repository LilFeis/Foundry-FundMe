// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {HelperConfig, CodeConstants} from "../../script/HelperConfig.s.sol";

contract FundMeTest is Test {
    FundMe public fundMe;
    HelperConfig public helperConfig;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 10e18;
    uint256 constant BALANCE = 10 ether;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306 );
        DeployFundMe deployFundMe = new DeployFundMe();
        (fundMe, helperConfig) = deployFundMe.run(); 
        vm.deal(USER, BALANCE); 
    }

    function testMinUSD() view public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }
 
    function testOwner() view public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeed() view public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailwithoutEnoughETH() public {
        vm.expectRevert(); // hey, the next line should revert
        //assert (This tx fails/reverts)
        fundMe.fund(); //send 0 value
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); //The next tx will be sent form user

        fundMe.fund{value: SEND_VALUE}();
        assertEq(fundMe.getAddressToAmountFunded(USER), SEND_VALUE); //amount funded == 10e18
    }

    function testAddsFunderToFundersArray() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert(); // hey, the next line should revert
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange 
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw(); 

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        //uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(startingOwnerBalance + startingFundMeBalance, endingOwnerBalance);
    }

    function testWithdrawWithMultipleFunders() public funded () {
        uint160 numberOfFunders = 10;
        uint160 stratingFunderIndex = 1;
         
        // Arrange
        for(uint160 i = stratingFunderIndex; i <= numberOfFunders; i++) {
            //vm.prank() new address
            //vm.deak() new deal to the address
            //address()
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }

} 
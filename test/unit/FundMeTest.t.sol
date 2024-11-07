//SPDX-LICENSE-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";


contract FundMeTest is Test {

    FundMe fundme;

    address USER = makeAddr("Hir");
    uint256 constant AMOUNT = 10e18;
    uint256 constant STARTING_BAL = 10e19;

    modifier funded(){
        vm.prank(USER);
        fundme.fund{value : AMOUNT}();
        _;
    }

    function setUp() external {
        // fundme = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundme = new DeployFundMe();
        fundme = deployFundme.run();
        vm.deal(USER, STARTING_BAL);
    }

    function testMinimumDollar() public view{
        assertEq(fundme.MINIMUM_USD(), 1e15);
    }


    function testOwnserMsgSender() public view{
        assertEq(fundme.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view{
        uint256 version = fundme.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public{
        vm.expectRevert("didn't sent enough Eth");
        fundme.fund();
    }

    function testFundUpdateFundedDataStructure() public{
        vm.prank(USER);
        fundme.fund{value : AMOUNT}();
        uint256 amountFunded = fundme.getAddressToAmountFunded(USER);
        assertEq(amountFunded, AMOUNT);
    }

    function testAddsToFunderToArrayOfFunders() public{
        vm.prank(USER);
        fundme.fund{value : AMOUNT}();

        address funder = fundme.getFunders(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded{
        vm.prank(USER);
        fundme.fund{value : AMOUNT}(); 

        vm.expectRevert("Must be owner !");
        fundme.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded{
        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundmeBalance = address(fundme).balance;

        vm.prank(fundme.getOwner());
        fundme.withdraw();

        uint256 endingOwnerBalance = fundme.getOwner().balance;
        uint256 endingFundmeBalance = address(fundme).balance;

        assertEq(startingOwnerBalance + startingFundmeBalance, endingOwnerBalance);
        assertEq(endingFundmeBalance, 0);

    } 


    function testWithdrawFromMultipleFunders() public funded{
        uint160 numberOfFuunders = 10;
        uint160 startingFunderIndex = 1;

        for(uint160 i = startingFunderIndex; i < numberOfFuunders; i++){
            hoax(address(i), AMOUNT);
            fundme.fund{value : AMOUNT}();
        }

        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundmeBalance = address(fundme).balance;

        vm.prank(fundme.getOwner());
        fundme.withdraw();

        assert(address(fundme).balance == 0);
        assert(startingFundmeBalance + startingOwnerBalance == fundme.getOwner().balance);

      }

    function testWithdrawFromMultipleFunderscheap() public funded{
        uint160 numberOfFuunders = 10;
        uint160 startingFunderIndex = 1;

        for(uint160 i = startingFunderIndex; i < numberOfFuunders; i++){
            hoax(address(i), AMOUNT);
            fundme.fund{value : AMOUNT}();
        }

        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundmeBalance = address(fundme).balance;

        vm.prank(fundme.getOwner());
        fundme.cheaperWithdraw();

        assert(address(fundme).balance == 0);
        assert(startingFundmeBalance + startingOwnerBalance == fundme.getOwner().balance);

      }
}
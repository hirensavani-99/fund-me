// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConvertor} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";


error FundMe__NotOwner();

contract FundMe{
    using PriceConvertor for uint256;

    uint256 public constant MINIMUM_USD = 1e15;
    address private immutable i_owner;
    address[] private s_funders;
    mapping(address funder => uint256 amountFunded) private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;
    
    constructor(address priceFeed){
        i_owner = msg.sender;
        s_priceFeed =  AggregatorV3Interface(priceFeed);
    } 

    modifier onlyOwner(){
    require(msg.sender == i_owner,"Must be owner !");
    _;
    }



    function fund() public payable {
        
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD , "didn't sent enough Eth");
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender]  +=  msg.value;
    }


    function cheaperWithdraw() public onlyOwner(){

        uint256 funderLength = s_funders.length;

         for(uint256 funderIndex = 0; funderIndex < funderLength; funderIndex++){
             address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;

         }

            s_funders = new address[](0);
            (bool callSuccess,)= payable(msg.sender).call{value: address(this).balance}("");
            require(callSuccess, "Call failled");
    } 

    function withdraw() public onlyOwner{
        
        for(uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++){
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;

            
        }

        s_funders = new address[](0);
            (bool callSuccess,)= payable(msg.sender).call{value: address(this).balance}("");
            require(callSuccess, "Call failled");
    }


    function getVersion() public view returns(uint256){
        return s_priceFeed.version();
    }

   
        


    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
    

    function getAddressToAmountFunded(address fundingAddress) public view returns(uint256){
        return s_addressToAmountFunded[fundingAddress];
    }
    
    function getFunders(uint256 index) public view returns(address){
        return s_funders[index];
    }

    function getOwner() public view returns(address){
        return i_owner;
    }

}
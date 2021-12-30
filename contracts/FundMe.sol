// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;




// Brownie can't import from NPM packages but can from Github

//import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

// Interfaces compile down to ABI Application Binary Interface:
// What functions can we use and what function can we call other contracts with
interface AggregatorV3Interface {

  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

contract FundMe { 
    
    // using A for B => attaching library functions from A to a type B
    using SafeMathChainlink for uint256;
    
    mapping(address => uint256) public addressToAmountFunded;
    // There is no easy way to iterate through a map, the we create an array
    address[] public funders;



    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender; // So that the person that deploys it is the owner

    }
    
    // The quilifyer "payable" indicates that the function can be used to
    // To pay for things. The quantity can be specified via the "value" of
    // The transaction. All this info is in the keyword msg.


    
    // Example 50$ minimum fund
    function fund() public payable {
        uint256 minumumUsd = 50 * 10**18;
        
        // This operates the same as if(not enough) revert with message ""
        require(getConversionRate(msg.value) >= minumumUsd, "You need to spend more ETH");
        
        addressToAmountFunded[msg.sender] += msg.value;

        funders.push(msg.sender);
        
        // Let's set a minmum value. But in USD what is the equivalent?
        // We need an oracle, we will use Chainlink. Centralized Oracles
        // Can ruin all decentrality of all the network.
        
    }

    function getEntranceFee() public view returns(uint256) {
      // Minimum USD to fund
      uint256 minimumUSD = 50*10**18;
      uint256 price = getPrice();
      uint256 precision = 1*10**18;
      return (minimumUSD*precision)/price; // In 18 decimals
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _; // Mandatory

    }
    // A modifier modifies a certain property of a function
    function withdraw() payable onlyOwner public {
        // Needs to be limited so that only the owner can withdraw funds
        //require(msg.sender == owner);
        msg.sender.transfer(address(this).balance); // address(this) = address of contract 
        for(uint256 i = 0; i < funders.length; ++i) {
          addressToAmountFunded[funders[i]] = 0;
        }
        funders = new address[](0);
    }
    
    function getVersion() public view returns(uint256) {
        return priceFeed.version();
    }
    
    function getPrice() public view returns(uint256) {
        (,int256 answer,,,) = priceFeed.latestRoundData();
        // The aggregator works with 8 decimals, so we add the 10 left
        // so the return has 18 decimals
        return uint256(answer*(10**10));
        
    }
    
    function getConversionRate(uint256 _weiAmmount) public view returns(uint256) {
        uint256 weiPrice = getPrice(); // (ETH/USD)*10^18
        uint256 totalUsd = (weiPrice*_weiAmmount); // In wei
        return totalUsd/1000000000000000000;
        // Usd returned in 18 deciamls! 
    }
}
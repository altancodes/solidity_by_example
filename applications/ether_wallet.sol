/* An example of a basic wallet
1. Anyone can send ETH
2. Only the owner can withdraw funds
*/

pragma solidity ^0.8.10;

contract EtherWallet {
    address payable public owner;

    constructor () {
        // The payable keyword lets the contract know that it can send money there
        owner = payable(msg.sender);
    }

    receive() external payable {

    }
    
    function() withdraw(uint_ amount) {
        require(msg.sender == owner, "caller is not an owner");
        // Same applies here too
        payable(msg.sender).transfer(_amount);
    }

    function() getBalance() external view returns (uint){
        return address(this).balance;
    }
}
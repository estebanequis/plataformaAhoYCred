//SPDX-License-Identifier:MIT;
pragma solidity ^0.6.1;

contract Practico1 {
    address public owner;

    constructor() public payable {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    function sum(uint x, uint y) public pure returns(uint){
        return x + y;
    }

    function getBalance() public view onlyOwner returns(uint256){
        return address(this).balance;
    }

    uint public index = 0;
    event messageEvent(uint indexed _index, string _message);
    function publishEvent(string memory _message) public {
        index++;
        emit messageEvent(index, _message);
    }
}
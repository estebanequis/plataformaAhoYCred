//SPDX-License-Identifier:MIT
pragma solidity ^0.6.1;

contract ContractWithSelfDestruct {
    address payable public owner;
    uint public number;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function setNumber(uint num) public {
        number = num;
    }
    
    function destroyContract() public onlyOwner() {
        selfdestruct(owner);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, 'Not the owner');
        _;
    }
}
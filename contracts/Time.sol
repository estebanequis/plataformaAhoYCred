pragma solidity ^0.5.1;

contract Time {
    uint public someDate = 1604959520;
    bool public close = false;
    
    constructor() public {}
    
    function ValidateDate() public {
        if(block.timestamp >= someDate){
            close = true;
        }
    }
    
    function getBlockTime() public view returns(uint){
        return block.timestamp;
    }
}
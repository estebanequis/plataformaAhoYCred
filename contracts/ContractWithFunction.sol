pragma solidity ^0.6.1;

contract ContractWithFunction {
    
    uint public myFunctionValue = 10;
    
    function setMyFunctionValue() public {
        myFunctionValue = 5;
    }
    
    function getMyFunctionValue() public view returns(uint) {
        return myFunctionValue;
    }
}
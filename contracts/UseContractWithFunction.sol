pragma solidity ^0.6.1;

import './ContractWithFunction.sol';

contract UseContractWithFunction {
    
    ContractWithFunction public myFunction;
    uint public result = 15;
    
    function setMyFunctionAddress(ContractWithFunction _address) public {
        myFunction = _address;
    }
    
    function setResult() public {
        result = myFunction.myFunctionValue();
    }
    
    function callSetMyFunctionValue() public view {
        myFunction.getMyFunctionValue.gas(100)();
    }
}
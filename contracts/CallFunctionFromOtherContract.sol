pragma solidity ^0.6.1;

contract CallFunctionFromOtherContract {
    uint public myValue = 100;
    address public myFunction;
    uint public result = 15;
    
    function setMyFunctionAddress(address _address) public {
        myFunction = _address;
    }
    
    function callSetMyFunctionValue() public  {
        bytes memory methodToCall = abi.encodeWithSignature("myFunctionValue()");
        (bool _success, bytes memory _retunData) = myFunction.call(methodToCall);
        result = abi.decode(_retunData, (uint));
    }
    
    function delegatecallSetMyFunctionValue() public  {
        bytes memory methodToCall = abi.encodeWithSignature("myFunctionValue()");
        (bool _success, bytes memory _retunData) = myFunction.delegatecall(methodToCall);
        result = abi.decode(_retunData, (uint))+1;
    }
    
    function staticcallSetMyFunctionValue() public  {
        bytes memory methodToCall = abi.encodeWithSignature("myFunctionValue()");
        (bool _success, bytes memory _retunData) = myFunction.staticcall(methodToCall);
        result = abi.decode(_retunData, (uint))+1;
    }
}
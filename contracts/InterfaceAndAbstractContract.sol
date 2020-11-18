//SPDX-License-Identifier:MIT
pragma solidity ^0.6.1;

interface myInterface {
    function myFunction() external view returns(uint);
}

abstract contract myAbstractContract {
    uint myInt = 10;
    function myFunction() public virtual view returns(uint);
    function myFunctionWithCode() public virtual view returns(uint){
        return myInt * 10;
    } 
}


contract myContractWithCode is myAbstractContract {
    function myFunction() public override view returns(uint) {
        return myInt;
    }
}
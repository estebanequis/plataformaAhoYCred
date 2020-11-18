//SPDX-License-Identifier:MIT
pragma solidity ^0.6.1;

contract BaseContract {
    uint public myVariable = 10;
    
    function getMyAddress() public view returns(address){
        return address(this);
    }
}


contract contractBuilder {
    BaseContract newContract;
    
    function createContract() public {
        newContract = new BaseContract();
    }
    
    function getNewContractAddress() public view returns(address){
        return newContract.getMyAddress();
    }
}
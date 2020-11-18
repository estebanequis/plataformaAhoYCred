//SPDX-License-Identifier:MIT;
pragma solidity ^0.6.1;

contract Padre {
    string public publicVariable;
    string private privateVariable;
    string internal internalVariable;
    
    constructor() public {
        publicVariable = "Constructor en Padre.";
        privateVariable = "Constructor en Padre.";
        internalVariable = "Constructor en Padre.";
    }
    
    function PublicFunction() public virtual { publicVariable = 'PublicFunction en Padre'; }
    function ExternalFunction() external virtual { privateVariable = 'ExternalFunction en Padre'; }
    
    function getPrivateVariable() public view returns(string memory){ return privateVariable; }
    function getInternalVariable() public view returns(string memory){ return internalVariable; }
}
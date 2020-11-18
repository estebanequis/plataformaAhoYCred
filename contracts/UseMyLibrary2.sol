//SPDX-License-Identifier:MIT
pragma solidity ^0.6.1;

import "./MyLibrary.sol";

contract UseMyLibrary2 {
    using MyLibrary for uint;
    uint public myInt = 2;
    
    function Suma() public returns(uint){
        myInt = myInt.Sum(3);
    }
}
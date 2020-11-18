//SPDX-License-Identifier:MIT
pragma solidity ^0.6.1;

import "./MyLibrary.sol";

contract UseMyLibrary {
    function Suma() public pure returns(uint){
        return MyLibrary.Sum(2, 3);
    }
}
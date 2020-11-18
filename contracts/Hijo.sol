//SPDX-License-Identifier:MIT;
pragma solidity ^0.6.1;

import './Padre.sol';

contract Hijo is Padre {
     function PublicFunction() public override { publicVariable = 'PublicFunction en Hijo'; }
     function PublicFunctionWithSuper() public { super.PublicFunction(); }
     function PublicFunctionWithoutOverride() public { publicVariable = 'PublicFunction en Hijo without override'; }
     function InternalFunction() public { internalVariable = 'InternalFunction en Hijo'; }
}
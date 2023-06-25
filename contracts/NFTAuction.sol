// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract NFTAuction {
    constructor() {
        //construtor
    }

    uint256 public myNumber;

    function setNumber(uint256 _number) public {
        myNumber = _number;
    }
    
    function getNumber() view public {
      
    }
}

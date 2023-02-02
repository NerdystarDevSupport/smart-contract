// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SuperOperators is Ownable {

    mapping(address => bool) internal _superOperators;

    event SuperOperator(address superOperator, bool enabled);

    modifier onlySuperOperator() {
        require(_superOperators[msg.sender], "SuperOperators: not super operators");
        _;
    }

    function setSuperOperator(address superOperator, bool enabled) external onlyOwner {
        _superOperators[superOperator] = enabled;
        emit SuperOperator(superOperator, enabled);
    }

    function isSuperOperator(address who) public view returns (bool) {
        return _superOperators[who];
    }
}
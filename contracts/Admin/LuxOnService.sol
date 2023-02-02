// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

contract LuxOnService is Ownable {
    mapping(address => bool) isInspection;

    event Inspection(address contractAddress, uint256 timestamp, bool live);

    function isLive(address contractAddress) public view returns (bool) {
        return !isInspection[contractAddress];
    }

    function setInspection(address[] memory contractAddresses, bool _isInspection) external onlyOwner {
        for (uint256 i = 0; i < contractAddresses.length; i++) {
            isInspection[contractAddresses[i]] = _isInspection;
            emit Inspection(contractAddresses[i], block.timestamp, _isInspection);
        }
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./SuperOperators.sol";

contract RealOwner is SuperOperators {
    event RealOwnerTransferred(uint256 tokenId, address indexed previousRealOwner, address indexed newRealOwner);

    mapping (uint256 => address) public realOwnerList;

    function getRealOwner(uint256 tokenId) public view returns (address) {
        return realOwnerList[tokenId];
    }

    function setRealOwner(address _previousRealOwner, address realOwner, uint256 tokenId) external onlySuperOperator {
        require(_previousRealOwner != realOwnerList[tokenId], "Payback: token address is the zero address");
        address previousRealOwner = realOwnerList[tokenId];
        realOwnerList[tokenId] = realOwner;
        emit RealOwnerTransferred(tokenId, previousRealOwner, realOwner);
    }
}

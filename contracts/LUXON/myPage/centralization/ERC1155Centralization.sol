// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "/contracts/LUXON/utils/SuperOperators.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract ERC1155Centralization is SuperOperators {

    event transferRealOwner(address indexed tokenAddress, uint256 tokenId, address indexed previousRealOwner, uint256 previousRealOwnerAmount, address indexed newRealOwner, uint256 newRealOwnerAmount, uint256 amount);

    address[] private tokenAddresses;

    mapping(address => mapping(uint256 => mapping(address => uint256))) centralizationData;

    function addToeknAddresses(address[] memory _tokenAddresses) external onlyOwner {
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            tokenAddresses.push(_tokenAddresses[i]);
        }
    }

    function getRealOwnerAmount(address _tokenAddress, uint256 _tokenId, address _realOwner) public view returns (uint256) {
        return centralizationData[_tokenAddress][_tokenId][_realOwner];
    }

    function transferCenter(address _previousRealOwner, address _tokenAddress, uint256 _tokenId, address _realOwner, uint256 _amount) external onlySuperOperator {
        require(centralizationData[_tokenAddress][_tokenId][_previousRealOwner] >= _amount, "not real owner");

        emit transferRealOwner(_tokenAddress, _tokenId, _previousRealOwner, centralizationData[_tokenAddress][_tokenId][_previousRealOwner], _realOwner, centralizationData[_tokenAddress][_tokenId][_realOwner], _amount);

        centralizationData[_tokenAddress][_tokenId][_previousRealOwner] -= _amount;
        centralizationData[_tokenAddress][_tokenId][_realOwner] += _amount;
    }

    function setCentralizationData(address _tokenAddress, uint256 _tokenId, address _realOwner, uint256 _amount) external onlySuperOperator {
        centralizationData[_tokenAddress][_tokenId][_realOwner] = _amount;
        ERC1155(_tokenAddress).safeTransferFrom(_realOwner, address(this), _tokenId, _amount, '');
    }

    function decentralizationData(address receiver, address _tokenAddress, uint256 _tokenId, uint256 _amount) external onlySuperOperator {
        require(_amount <= centralizationData[_tokenAddress][_tokenId][receiver], "not real owner");
        ERC1155(_tokenAddress).safeTransferFrom(address(this), receiver, _tokenId, _amount, '');
        centralizationData[_tokenAddress][_tokenId][receiver] -= _amount;
    }
}
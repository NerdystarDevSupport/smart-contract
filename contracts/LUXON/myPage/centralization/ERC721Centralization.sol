// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "/contracts/LUXON/utils/LuxOnSuperOperators.sol";
import "/contracts/LUXON/utils/ERC721LUXON.sol";

contract ERC721Centralization is LuxOnSuperOperators {

    event ERC721Deposit(address indexed owner, address indexed previousRealOwner, address indexed tokenAddress, uint256 tokenId);
    event ERC721Withdraw(address indexed owner, address indexed tokenAddress, uint256[] tokenIds);

    event SetRealOwner(address indexed tokenAddress, uint256 indexed tokenId, address indexed realOwner);
    event TransferCenter(address previousRealOwner, address indexed tokenAddress, uint256 indexed tokenId, address indexed _realOwner);
    event SetCentralizationData(address indexed owner, address indexed previousRealOwner, address indexed tokenAddress, uint256 tokenId);
    event DecentralizationData(address indexed receiver, address indexed tokenAddress, uint256[] tokenIds);

    constructor(
        string memory operator,
        address luxOnAdmin
    ) LuxOnSuperOperators(operator, luxOnAdmin) {}

    mapping(address => mapping(uint256 => address)) private centralizationData;

    function getRealOwner(address _tokenAddress, uint256 _tokenId) public view returns (address) {
        return centralizationData[_tokenAddress][_tokenId];
    }

    function getRealOwner(address _tokenAddress, address _realOwner) public view returns (uint256[] memory) {
        uint256 totalSupply = ERC721LUXON(_tokenAddress).totalSupply();

        uint256 realOwnerTokenCount = 0;
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (centralizationData[_tokenAddress][i] == _realOwner) {
                realOwnerTokenCount++;
            }
        }
        uint256[] memory realOwnerTokenList = new uint256[](realOwnerTokenCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (centralizationData[_tokenAddress][i] == _realOwner) {
                realOwnerTokenList[index++] = i;
            }
        }

        return realOwnerTokenList;
    }

    function setRealOwnerOnce(address _tokenAddress, uint256 _tokenId, address _realOwner) external onlySuperOperator {
        require(address(0) == centralizationData[_tokenAddress][_tokenId], "not vaild previous owner");
        centralizationData[_tokenAddress][_tokenId] = _realOwner;

        emit SetRealOwner(_tokenAddress, _tokenId, _realOwner);
    }

    function setRealOwner(address _tokenAddress, uint256[] memory _tokenIds, address _realOwner) external onlySuperOperator {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(address(0) == centralizationData[_tokenAddress][_tokenIds[i]], "not vaild previous owner");
            centralizationData[_tokenAddress][_tokenIds[i]] = _realOwner;
            emit SetRealOwner(_tokenAddress, _tokenIds[i], _realOwner);
        }
    }

    function transferCenter(address _previousRealOwner, address _tokenAddress, uint256 _tokenId, address _realOwner) external onlySuperOperator {
        require(_previousRealOwner == centralizationData[_tokenAddress][_tokenId], "not real owner");
        centralizationData[_tokenAddress][_tokenId] = _realOwner;
        emit TransferCenter(_previousRealOwner, _tokenAddress, _tokenId, _realOwner);
    }

    function setCentralizationDataOnceWithLog(address _tokenAddress, uint256 _tokenId, address _realOwner) external onlySuperOperator {
        ERC721LUXON(_tokenAddress).transferFrom(_realOwner, address(this), _tokenId);
        emit ERC721Deposit(_realOwner, centralizationData[_tokenAddress][_tokenId], _tokenAddress, _tokenId);
        centralizationData[_tokenAddress][_tokenId] = _realOwner;
    }

    function setCentralizationDataOnce(address _tokenAddress, uint256 _tokenId, address _realOwner) external onlySuperOperator {
        ERC721LUXON(_tokenAddress).transferFrom(_realOwner, address(this), _tokenId);
        emit SetCentralizationData(_realOwner, centralizationData[_tokenAddress][_tokenId], _tokenAddress, _tokenId);
        centralizationData[_tokenAddress][_tokenId] = _realOwner;
    }

    function setCentralizationDataWithLog(address _tokenAddress, uint256[] memory _tokenIds, address _realOwner) external onlySuperOperator {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            ERC721LUXON(_tokenAddress).transferFrom(_realOwner, address(this), _tokenIds[i]);
            emit ERC721Deposit(_realOwner, centralizationData[_tokenAddress][_tokenIds[i]], _tokenAddress, _tokenIds[i]);
            centralizationData[_tokenAddress][_tokenIds[i]] = _realOwner;
        }
    }

    function setCentralizationData(address _tokenAddress, uint256[] memory _tokenIds, address _realOwner) external onlySuperOperator {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            ERC721LUXON(_tokenAddress).transferFrom(_realOwner, address(this), _tokenIds[i]);
            emit SetCentralizationData(_realOwner, centralizationData[_tokenAddress][_tokenIds[i]], _tokenAddress, _tokenIds[i]);
            centralizationData[_tokenAddress][_tokenIds[i]] = _realOwner;
        }
    }

    function decentralizationDataOnce(address receiver, address _tokenAddress, uint256 _tokenId) external onlySuperOperator {
        require(receiver == centralizationData[_tokenAddress][_tokenId], "not real owner");
        ERC721LUXON(_tokenAddress).transferFrom(address(this), centralizationData[_tokenAddress][_tokenId], _tokenId);
        uint256[] memory tokenIds = new uint256[](1);
        emit DecentralizationData(receiver, _tokenAddress, tokenIds);
    }

    function decentralizationDataOnceWithLog(address receiver, address _tokenAddress, uint256 _tokenId) external onlySuperOperator {
        require(receiver == centralizationData[_tokenAddress][_tokenId], "not real owner");
        ERC721LUXON(_tokenAddress).transferFrom(address(this), centralizationData[_tokenAddress][_tokenId], _tokenId);
        uint256[] memory tokenIds = new uint256[](1);
        emit ERC721Withdraw(receiver, _tokenAddress, tokenIds);
    }

    function decentralizationData(address receiver, address _tokenAddress, uint256[] memory _tokenIds) external onlySuperOperator {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(receiver == centralizationData[_tokenAddress][_tokenIds[i]], "not real owner");
            ERC721LUXON(_tokenAddress).transferFrom(address(this), centralizationData[_tokenAddress][_tokenIds[i]], _tokenIds[i]);
        }

        emit DecentralizationData(receiver, _tokenAddress, _tokenIds);
    }

    function decentralizationDataWithLog(address receiver, address _tokenAddress, uint256[] memory _tokenIds) external onlySuperOperator {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(receiver == centralizationData[_tokenAddress][_tokenIds[i]], "not real owner");
            ERC721LUXON(_tokenAddress).transferFrom(address(this), centralizationData[_tokenAddress][_tokenIds[i]], _tokenIds[i]);
        }

        emit ERC721Withdraw(receiver, _tokenAddress, _tokenIds);
    }
}
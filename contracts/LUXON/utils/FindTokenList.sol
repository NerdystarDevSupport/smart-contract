// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./IERC721LUXON.sol";

contract FindTokenList {

    struct Erc20 {
        address addr;
        uint amount;
    }

    struct Erc1155Info {
        uint256 token_id;
        uint256 balance;
        string uri;
    }

    struct Erc1155 {
        address addr;
        Erc1155Info[] info;
    }

    function getErc20List(address[] calldata _addresses) public view returns (Erc20[] memory){
        Erc20[] memory list = new Erc20[](_addresses.length);
        uint div = 10**18;
        for (uint i = 0; i < _addresses.length; i++) {
            IERC20 token = IERC20(_addresses[i]);
            uint amount = (token.balanceOf(address(msg.sender))/div);
            list[i] = Erc20(_addresses[i], amount);
        }
        return list;
    }

    function getErc721List(address _address, address sender) public view returns (uint256[] memory) {
        uint256 currentTokenId = IERC721LUXON(_address).nextTokenId();
        uint256[] memory totalTokenIds = new uint256[](currentTokenId);
        uint256 totalCount = 0;
        for (uint256 i = 1; i < currentTokenId; i++) {
            try IERC721LUXON(_address).ownerOf(i) returns (address owner) {
                if (address(owner) == address(sender)) {
                    totalTokenIds[i] = i;
                    totalCount++;
                }
            } catch {}
        }

        uint256[] memory tokenIds = new uint256[](totalCount);
        uint256 index = 0;
        for (uint256 i = 1; i < totalTokenIds.length; i++) {
            if (totalTokenIds[i] != 0) {
                tokenIds[index++] = totalTokenIds[i];
            }
        }
        return tokenIds;
    }

    function getErc1155List(address _address, address _sender, uint[] memory _tokenIds, bool isReturnZero) public view returns (Erc1155 memory) {
        Erc1155Info[] memory erc1155Info = new Erc1155Info[](_tokenIds.length);
        ERC1155 token = ERC1155(_address);
        uint256 index = 0;
        for (uint i = 0; i < _tokenIds.length; i++) {
            string memory uri = token.uri(_tokenIds[i]);
            uint256 balance = token.balanceOf(_sender, _tokenIds[i]);
            if (balance != 0 || isReturnZero) {
                erc1155Info[i] = Erc1155Info(_tokenIds[i], balance, uri);
            } else {
                index ++;
            }
        }
        if (!isReturnZero) {
            Erc1155Info[] memory _erc1155Info = new Erc1155Info[](_tokenIds.length - index);
            for (uint256 i = 0; i < _tokenIds.length - index; i++) {
                _erc1155Info[i] = erc1155Info[i];
            }
            return Erc1155(_address, _erc1155Info);
        } else {
            return Erc1155(_address, erc1155Info);
        }
    }
}
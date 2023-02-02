// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "/contracts/LUXON/utils/LuxOnLive.sol";
import "/contracts/LUXON/myPage/centralization/ERC721Centralization.sol";
import "/contracts/LUXON/myPage/centralization/ERC1155Centralization.sol";
import "/contracts/LUXON/utils/IERC20LUXON.sol";

contract CentralizationGate is LuxOnLive {
    address private erc721Centralization;
    address private erc1155Centralization;

    constructor (
        address _erc721Centralization,
        address _erc1155Centralization,
        address luxOnService
    ) LuxOnLive(luxOnService) {
        erc721Centralization = _erc721Centralization;
        erc1155Centralization = _erc1155Centralization;
    }

    function getErc721Centralization() public view returns (address) {
        return erc721Centralization;
    }

    function getErc1155Centralization() public view returns (address) {
        return erc1155Centralization;
    }

    function setErc721Centralization(address _erc721Centralization) external onlyOwner {
        erc721Centralization = _erc721Centralization;
    }

    function setErc1155Centralization(address _erc1155Centralization) external onlyOwner {
        erc1155Centralization = _erc1155Centralization;
    }

    function desperadoDepositErc721(address _tokenAddress, uint256[] memory _tokenIds) external isLive {
        ERC721Centralization(erc721Centralization).setCentralizationDataWithLog(_tokenAddress, _tokenIds, msg.sender);
    }

    function desperadoWithdrawErc721(address _tokenAddress, uint256[] memory _tokenIds) external isLive {
        ERC721Centralization(erc721Centralization).decentralizationDataWithLog(msg.sender, _tokenAddress, _tokenIds);
    }

    function desperadoDepositErc1155(address _tokenAddress, uint256 _tokenId, uint256 amount) external isLive {
        ERC1155Centralization(erc1155Centralization).setCentralizationData(_tokenAddress, _tokenId, msg.sender, amount);
    }

    function desperadoWithdrawErc1155(address _tokenAddress, uint256 _tokenId, uint256 amount) external isLive {
        ERC1155Centralization(erc1155Centralization).decentralizationData(msg.sender, _tokenAddress, _tokenId, amount);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../../utils/LuxOnLive.sol";
import "../../utils/IERC721LUXON.sol";
import "../../utils/IGachaTicket.sol";
import "../../myPage/centralization/ERC721Centralization.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../../Admin/data/CharacterData.sol";
import "../../../Admin/data/GachaData.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract GachaMachineByGachaTicket is ReentrancyGuard, LuxOnLive, ERC1155Holder {
    event GachaByGachaTicket(address indexed owner, uint256 indexed gachaTicketTokenId, bool indexed isCentralization, uint256[] tokenIds);

    event SetMintGoodsInfo(address indexed mintGoodsAddress, uint256[] tokenIds);
    event SetMintAddress(address indexed mintAddress);
    event SetCentralizationAddress(address indexed centralizationAddress);
    event SetGachaDataAddress(address indexed gachaDataAddress);
    event SetCharacterDataAddress(address indexed characterDataAddress);
    event SetIsCentralization(bool indexed isCentralization);
    event Withdraw(uint256 amount);

    bool private isCentralization = false;
    address private mintAddress;

    struct GachaInfo {
        uint256 tokenId;
        uint256 amount;
        bool isCentralization;
    }

    struct MintGoodsInfo {
        address mintGoodsAddress;
        uint256[] tokenIds;
    }
    MintGoodsInfo private mintGoodsInfo;
    mapping(address => mapping(uint256 => bool)) private mintGoodsList;

    address private centralizationAddress;
    address private characterDataAddress;
    address private gachaDataAddress;

    constructor(
        address _mintAddress,
        MintGoodsInfo memory _mintGoodsInfo,
        address _centralizationAddress,
        address _characterDataAddress,
        address _gachaDataAddress,
        address luxOnService
    ) LuxOnLive(luxOnService) {
        mintGoodsInfo = _mintGoodsInfo;
        for (uint256 i = 0; i < _mintGoodsInfo.tokenIds.length; i++) {
            mintGoodsList[_mintGoodsInfo.mintGoodsAddress][_mintGoodsInfo.tokenIds[i]] = true;
        }
        mintAddress = _mintAddress;
        centralizationAddress = _centralizationAddress;
        characterDataAddress = _characterDataAddress;
        gachaDataAddress = _gachaDataAddress;
    }

    //------------------ get ------------------//

    function getMintGoodsInfo() public view returns (MintGoodsInfo memory) {
        return mintGoodsInfo;
    }

    function getMintAddress() public view returns (address) {
        return mintAddress;
    }

    function getCentralizationAddress() public view returns (address) {
        return centralizationAddress;
    }

    function getCharacterDataAddress() public view returns (address) {
        return characterDataAddress;
    }

    function getGachaDataAddress() public view returns (address) {
        return gachaDataAddress;
    }

    function getIsCentralization() public view returns (bool) {
        return isCentralization;
    }

    //------------------ set ------------------//

    function setMintGoodsInfo(MintGoodsInfo memory _mintGoodsInfo) external onlyOwner {
        for (uint256 i = 0; i < mintGoodsInfo.tokenIds.length; i++) {
            mintGoodsList[mintGoodsInfo.mintGoodsAddress][mintGoodsInfo.tokenIds[i]] = false;
        }
        mintGoodsInfo = _mintGoodsInfo;
        for (uint256 i = 0; i < mintGoodsInfo.tokenIds.length; i++) {
            mintGoodsList[mintGoodsInfo.mintGoodsAddress][mintGoodsInfo.tokenIds[i]] = true;
        }

        emit SetMintGoodsInfo(_mintGoodsInfo.mintGoodsAddress, _mintGoodsInfo.tokenIds);
    }

    function setMintAddress(address _mintAddress) external onlyOwner {
        mintAddress = _mintAddress;
        emit SetMintAddress(_mintAddress);
    }

    function setCentralizationAddress(address _centralizationAddress) external onlyOwner {
        centralizationAddress = _centralizationAddress;
        emit SetCentralizationAddress(_centralizationAddress);
    }

    function setGachaDataAddress(address _gachaDataAddress) external onlyOwner {
        gachaDataAddress = _gachaDataAddress;
        emit SetGachaDataAddress(_gachaDataAddress);
    }

    function setCharacterDataAddress(address _characterDataAddress) external onlyOwner {
        characterDataAddress = _characterDataAddress;
        emit SetCharacterDataAddress(_characterDataAddress);
    }

    function setIsCentralization(bool _isCentralization) external onlyOwner {
        isCentralization = _isCentralization;
        emit SetIsCentralization(_isCentralization);
    }

    //------------------ gacha ------------------//

    function gacha(GachaInfo memory _gachaInfo) external isLive {
        mintPay(_gachaInfo);
        IERC721LUXON(mintAddress).mint(msg.sender, _gachaInfo.amount);

        uint256 lastTokenId = IERC721LUXON(mintAddress).nextTokenId() - 1;
        uint256[] memory tokenIds = new uint256[](_gachaInfo.amount);
        for (uint256 i = 0; i < _gachaInfo.amount; i++) {
            tokenIds[i] = lastTokenId - i;
        }

        if (isCentralization && _gachaInfo.isCentralization) {
            ERC721Centralization(centralizationAddress).setCentralizationData(mintAddress, tokenIds, msg.sender);
        } else {
            ERC721Centralization(centralizationAddress).setRealOwner(mintAddress, tokenIds, msg.sender);
        }
        emit GachaByGachaTicket(msg.sender, _gachaInfo.tokenId, (isCentralization && _gachaInfo.isCentralization), tokenIds);
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
        emit Withdraw(address(this).balance);
    }

    //------------------ private ------------------//

    function mintPay(GachaInfo memory _gachaInfo) private {
        DspGachaData.GachaInfo memory gachaInfo = DspGachaData(gachaDataAddress).getGachaInfo(_gachaInfo.tokenId);
        require(gachaInfo.isValid, "not valid token id");
        require(mintGoodsList[mintGoodsInfo.mintGoodsAddress][_gachaInfo.tokenId], "not valid token id");
        IGachaTicket(mintGoodsInfo.mintGoodsAddress).burn(msg.sender, _gachaInfo.tokenId, _gachaInfo.amount);
    }
}

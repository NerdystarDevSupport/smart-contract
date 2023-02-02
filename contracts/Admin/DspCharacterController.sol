// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "/contracts/LUXON/utils/LuxOnLive.sol";
import "/contracts/LUXON/utils/IERC721LUXON.sol";
import "/contracts/LUXON/myPage/centralization/ERC721Centralization.sol";
import "/contracts/Admin/data/CharacterData.sol";

contract DspCharacterController is Ownable, LuxOnLive {
    event AddMintList(address indexed userAddress, address tokenAddress, uint256 characterId, string characterName, string reason);
    event BurnDspCharacter(address indexed userAddress, address tokenAddress, uint256 characterId, uint256 tokenId, string reason);
    event MintDspCharacter(address indexed userAddress, address tokenAddress, uint256[] characterIds, uint256[] tokenIds);

    enum Job { MINT, BURN }

    struct CharacterInfo {
        string characterName;
        uint256 tokenId;
        bool isValid;
    }

    struct JobInfo {
        address userAddress;
        uint256 characterId;
        string characterName;
        uint256 tokenId;
        string reason;
        Job job;
    }

    // user address => character id => true / false
    mapping(address => mapping(uint256 => CharacterInfo)) private mintList;

    address private tokenAddress;
    address private centralizationAddress;
    address private characterDataAddress;

    constructor(
        address _tokenAddress,
        address _centralizationAddress,
        address _characterDataAddress,
        address luxOnService
    ) LuxOnLive(luxOnService) {
        tokenAddress = _tokenAddress;
        centralizationAddress = _centralizationAddress;
        characterDataAddress = _characterDataAddress;
    }

    function getCharacterTokenAddress() public view returns (address) {
        return tokenAddress;
    }

    function getCentralizationAddress() public view returns (address) {
        return centralizationAddress;
    }

    function getCharacterDataAddress() public view returns (address) {
        return characterDataAddress;
    }

    function getMintList(address userAddress, uint256 characterId) public view returns (string memory, bool) {
        return (mintList[userAddress][characterId].characterName, mintList[userAddress][characterId].isValid);
    }

    function setCharacterTokenAddress(address _tokenAddress) external onlyOwner {
        tokenAddress = _tokenAddress;
    }

    function setCentralizationAddress(address _centralizationAddress) external onlyOwner {
        centralizationAddress = _centralizationAddress;
    }

    function setCharacterDataAddress(address _characterDataAddress) external onlyOwner {
        characterDataAddress = _characterDataAddress;
    }

    function dspCharacterControl(JobInfo[] memory jobInfos) external onlyOwner {
        for (uint256 i = 0; i < jobInfos.length; i++) {
            JobInfo memory _jobInfo = jobInfos[i];
            if (_jobInfo.job == Job.MINT) {
                setMintList(_jobInfo);
            } else if (_jobInfo.job == Job.BURN) {
                burnDspCharacter(_jobInfo);
            }
        }
    }

    function setMintList(JobInfo memory mintInfo) private {
        require(DspCharacterData(characterDataAddress).getCharacterInfoIsValid(mintInfo.characterName), "not valid character name");
        mintList[mintInfo.userAddress][mintInfo.characterId] = CharacterInfo(mintInfo.characterName, 0, true);
        emit AddMintList(mintInfo.userAddress, tokenAddress, mintInfo.characterId, mintInfo.characterName, mintInfo.reason);
    }

    function burnDspCharacter(JobInfo memory burnInfo) private {
        if (burnInfo.tokenId == 0) {
            if (mintList[burnInfo.userAddress][burnInfo.characterId].isValid &&
                mintList[burnInfo.userAddress][burnInfo.characterId].tokenId == 0) {
                delete mintList[burnInfo.userAddress][burnInfo.characterId];
            } else {
                IERC721LUXON(tokenAddress).burn(mintList[burnInfo.userAddress][burnInfo.characterId].tokenId);
            }
        } else {
            IERC721LUXON(tokenAddress).burn(burnInfo.tokenId);
        }
        emit BurnDspCharacter(burnInfo.userAddress, tokenAddress, burnInfo.characterId, burnInfo.tokenId, burnInfo.reason);
    }

    function mintDspCharacter(uint256[] memory characterIds) external isLive {
        string[] memory gachaIds = new string[](characterIds.length);
        for (uint256 i = 0; i < characterIds.length; i++) {
            require(mintList[msg.sender][characterIds[i]].isValid, "can not mint nft");
            gachaIds[i] = mintList[msg.sender][characterIds[i]].characterName;
        }
        IERC721LUXON(tokenAddress).mintByCharacterName(msg.sender, characterIds.length, gachaIds);

        uint256 lastTokenId = IERC721LUXON(tokenAddress).nextTokenId() - 1;
        uint256[] memory tokenIds = new uint256[](characterIds.length);
        for (uint256 i = 0; i < characterIds.length; i++) {
            tokenIds[i] = lastTokenId - i;
            mintList[msg.sender][characterIds[characterIds.length - 1 - i]].tokenId = tokenIds[i];
            mintList[msg.sender][characterIds[characterIds.length - 1 - i]].isValid = false;
        }

        ERC721Centralization(centralizationAddress).setRealOwner(tokenAddress, tokenIds, msg.sender);
        emit MintDspCharacter(msg.sender, tokenAddress, characterIds, tokenIds);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../utils/ERC721LUXON.sol";

contract LCT is ERC721LUXON {

    event MintByCharacterName(address indexed mintUser, uint256 indexed tokenId, string indexed name);
    event BurnCharacter(uint256 indexed tokenId, string indexed name);
    event SetCharacterName(uint256 indexed tokenId, string indexed name);

    struct Character {
        uint256 tokenId;
        string name;
    }

    constructor(
        string memory operator,
        address luxOnAdmin
    ) ERC721LUXON("Desperado: Character", "Character", operator, luxOnAdmin) {}

    mapping(uint256 => string) characterInfo;

    function mintByCharacterName(address mintUser, uint256 quantity, string[] memory characterName) external onlySuperOperator {
        require(characterName.length == quantity, "quantity != gacha count");
        uint256 tokenId = nextTokenId();
        for (uint8 i = 0; i < quantity; i++) {
            emit MintByCharacterName(mintUser, tokenId, characterName[i]);
            characterInfo[tokenId++] = characterName[i];
        }
        _safeMint(mintUser, quantity);
    }

    function mint(address mintUser, uint256 quantity) external onlySuperOperator {
        _safeMint(mintUser, quantity);
    }

    function getCharacterInfo(uint256 tokenId) public view returns (string memory) {
        return characterInfo[tokenId];
    }

    function getCharacterInfos(uint256[] memory tokenIds) public view returns (string[] memory) {
        string[] memory names = new string[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            names[i] = characterInfo[tokenIds[i]];
        }
        return names;
    }

    function burnCharacter(uint256 tokenId) external onlySuperOperator {
        _burn(tokenId);
        emit BurnCharacter(tokenId, characterInfo[tokenId]);
        delete characterInfo[tokenId];
    }

    function burnCharacters(uint256[] memory tokenIds) external onlySuperOperator {
        for (uint256 i = 0; i< tokenIds.length; i++) {
            _burn(tokenIds[i]);
            emit BurnCharacter(tokenIds[i], characterInfo[tokenIds[i]]);
            delete characterInfo[tokenIds[i]];
        }
    }

    function setCharacterName(Character[] memory _character) external onlySuperOperator {
        for (uint256 i = 0; i < _character.length; i++) {
            characterInfo[_character[i].tokenId] = _character[i].name;
            emit SetCharacterName(_character[i].tokenId, _character[i].name);
        }
    }
}
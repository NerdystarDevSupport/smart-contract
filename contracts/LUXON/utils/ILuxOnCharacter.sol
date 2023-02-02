// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface ILuxOnCharacter {
    struct Character {
        uint256 tokenId;
        string name;
    }
    function setCharacterName(Character[] memory _character) external;
}

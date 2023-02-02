// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC721LUXON {
    function mintByCharacterName(address mintUser, uint256 quantity, string[] memory gachaIds) external;
    function nextTokenId() external view returns (uint256);
    function burn(uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function totalSupply() external view returns (uint256);
    function mint(address mintUser, uint256 quantity) external;
}
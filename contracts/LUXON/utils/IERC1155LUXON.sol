// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC1155LUXON {
    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data) external;
    function getValueChipType() external view returns(uint32);
}
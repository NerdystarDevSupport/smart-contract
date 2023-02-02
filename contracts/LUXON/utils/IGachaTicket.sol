// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.13;

import "/contracts/LUXON/utils/ERC1155LUXON.sol";

interface IGachaTicket {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;
    function balanceOf(address account, uint256 id) external returns (uint256);
    function burn(address account, uint256 id, uint256 value) external;
    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external;
}

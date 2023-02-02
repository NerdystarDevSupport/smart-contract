// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20LUXON {
    function paybackFrom() external view returns (address);

    function addAllowanceIfNeeded(address owner, address spender, uint256 amountNeeded) external returns (bool success);
    function approveFor(address owner, address spender, uint256 amount) external returns (bool success);

    function paybackByMint(address to, uint256 amount) external;
    function paybackByTransfer(address to, uint256 amount) external;
    function burnFor(address owner, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

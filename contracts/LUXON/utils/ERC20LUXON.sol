// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ERC20LXN.sol";

contract ERC20LUXON is ERC20LXN {
    address internal _paybackFrom;

    constructor(
        string memory name_,
        string memory symbol_ ,
        string memory operator,
        address luxOnAdmin
    ) ERC20LXN(name_, symbol_, operator, luxOnAdmin) {}

    function setPaybackFrom(address paybackFrom_) external onlyOwner {
        _paybackFrom = paybackFrom_;
    }

    function paybackFrom() public view returns (address) {
        return _paybackFrom;
    }

    function paybackByMint(address to, uint256 amount) external onlySuperOperator {
        _mint(to, amount);
    }

    function paybackByTransfer(address to, uint256 amount) external onlySuperOperator {
        _transfer(_paybackFrom, to, amount);
    }
}
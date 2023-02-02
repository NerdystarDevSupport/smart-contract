// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "/contracts/LUXON/utils/LuxOnSuperOperators.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract Lxn is ERC20, ERC20Permit, ERC20Votes, LuxOnSuperOperators {
    constructor(
        string memory operator,
        address luxOnAdmin
    ) ERC20("LUXON", "LXN") ERC20Permit("LUXON") LuxOnSuperOperators(operator, luxOnAdmin) {
        _mint(msg.sender, 1200000000 * 10 ** uint(decimals()));
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override (ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override (ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override (ERC20, ERC20Votes) {
        super._burn(account, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool success) {
        if (msg.sender != from && !isSuperOperator(msg.sender)) {
            uint256 currentAllowance = allowance(from, msg.sender);
            if (currentAllowance != type(uint256).max) {
                require(currentAllowance >= amount, "Not enough funds allowed");
            unchecked {
                _approve(from, msg.sender, currentAllowance - amount);
            }
            }
        }
        _transfer(from, to, amount);
        return true;
    }

    function approveFor(address owner, address spender, uint256 amount) public returns (bool success) {
        require(msg.sender == owner || isSuperOperator(msg.sender), "msg.sender != owner && !superOperator");
        _approve(owner, spender, amount);
        return true;
    }

    function addAllowanceIfNeeded(address owner, address spender, uint256 amountNeeded) public returns (bool success) {
        require(msg.sender == owner || isSuperOperator(msg.sender), "msg.sender != owner && !superOperator");
        _addAllowanceIfNeeded(owner, spender, amountNeeded);
        return true;
    }

    function _addAllowanceIfNeeded(address owner, address spender, uint256 amountNeeded) private {
        if(amountNeeded > 0 && !isSuperOperator(spender)) {
            uint256 currentAllowance = allowance(owner, spender);
            if(currentAllowance < amountNeeded) {
                _approve(owner, spender, amountNeeded);
            }
        }
    }

    function burn(uint256 amount) external onlyOwner returns (bool) {
        require(amount > 0, "cannot burn 0 tokens");
        _burn(msg.sender, amount);
        return true;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./LuxOnSuperOperators.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20LXN is ERC20, LuxOnSuperOperators {
    constructor(
        string memory name_,
        string memory symbol_,
        string memory operator,
        address luxOnAdmin
    ) ERC20(name_, symbol_) LuxOnSuperOperators(operator, luxOnAdmin) {}

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

    function _addAllowanceIfNeeded(address owner, address spender, uint256 amountNeeded) internal {
        if(amountNeeded > 0 && !isSuperOperator(spender)) {
            uint256 currentAllowance = allowance(owner, spender);
            if(currentAllowance < amountNeeded) {
                _approve(owner, spender, amountNeeded);
            }
        }
    }

    function burnFor(address owner, uint256 amount) external onlySuperOperator returns (bool) {
        require(amount > 0, "cannot burn 0 tokens");
        _burn(owner, amount);
        return true;
    }
}
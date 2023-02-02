// develop 전용
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../LUXON/utils/IERC20LUXON.sol";

contract Airdrop is Ownable {
    address public airdropFrom = address(this);

    address private airdropToken;
    uint256 public maxAmount;

    constructor(address _airdropToken, uint256 amount) {
        airdropToken = _airdropToken;
        maxAmount = amount * 10 ** uint(IERC20LUXON(airdropToken).decimals());
    }

    function setAirdropFrom(address _airdropFrom) external onlyOwner {
        airdropFrom = _airdropFrom;
    }

    function setMaxAmount(uint256 _maxAmount) external onlyOwner {
        maxAmount = _maxAmount * 10 ** uint(IERC20LUXON(airdropToken).decimals());
    }

    function tokenAirdrop(uint256 amount) public {
        uint256 _amount = amount * 10 ** uint(IERC20LUXON(airdropToken).decimals());
        require(_amount <= maxAmount, "Less than 1000");
        IERC20(airdropToken).transferFrom(airdropFrom, msg.sender, _amount);
    }
}
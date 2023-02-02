// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC20LUXON.sol";

contract Payback is Ownable {
    struct PaybackInfo {
        address tokenAddress;
        uint256 percentageRate;
        uint256 percentage;
    }

    address private _tokenAddress;
    uint256 private _percentageRate;
    uint256 private _percentage;

    event PaybackTokenAddressTransferred(address indexed previousTokenAddress, address indexed newTokenAddress);
    event PaybackPercentageRateTransferred(uint256 indexed previousPaybackPercentageRate, uint256 indexed newPaybackPercentageRate);
    event PaybackPercentageTransferred(uint256 indexed previousPaybackPercentage, uint256 indexed newPaybackPercentage);

    constructor (PaybackInfo memory paybackInfo) {
        _transferTokenAddress(paybackInfo.tokenAddress);
        _transferPaybackPercentageRate(paybackInfo.percentageRate);
        _transferPaybackPercentage(paybackInfo.percentage);
    }

    modifier validPercentage() {
        require(getPaybackTokenAddress() != address(0), "Payback: token address is the zero address");
        require(getPaybackPercentageRate() >= 100, "Payback: percentage rate cannot be less than 100");
        require(getPaybackPercentage() >= 1, "Payback: percentage cannot be less than 1");
        _;
    }

    function getPaybackTokenAddress() public view virtual returns (address) {
        return _tokenAddress;
    }

    function getPaybackPercentageRate() public view virtual returns (uint256) {
        return _percentageRate;
    }

    function getPaybackPercentage() public view virtual returns (uint256) {
        return _percentage;
    }

    function transferTokenAddress(address newTokenAddress) external virtual onlyOwner {
        require(newTokenAddress != address(0), "Payback: token address is the zero address");
        _transferTokenAddress(newTokenAddress);
    }

    function _transferTokenAddress(address newTokenAddress) private {
        address oldTokenAddress = _tokenAddress;
        _tokenAddress = newTokenAddress;

        emit PaybackTokenAddressTransferred(oldTokenAddress, newTokenAddress);
    }

    function transferPaybackPercentageRate(uint256 newPercentageRate) external virtual onlyOwner {
        require(newPercentageRate <= 100, "Payback: percentage rate cannot be less than 100");
        _transferPaybackPercentageRate(newPercentageRate);
    }

    function _transferPaybackPercentageRate(uint256 newPercentageRate) private {
        uint256 oldPercentageRate = _percentageRate;
        _percentageRate = newPercentageRate;

        emit PaybackPercentageRateTransferred(oldPercentageRate, newPercentageRate);
    }

    function transferPaybackPercentage(uint256 newPercentage) external virtual onlyOwner {
        require(newPercentage <= 1, "Payback: percentage cannot be less than 1");
        _transferPaybackPercentage(newPercentage);
    }

    function _transferPaybackPercentage(uint256 newPercentage) private {
        uint256 oldPercentage = _percentage;
        _percentage = newPercentage;

        emit PaybackPercentageTransferred(oldPercentage, newPercentage);
    }

    function paybackByMint(address to, uint256 amount) internal virtual validPercentage {
        IERC20LUXON(_tokenAddress).paybackByMint(to, amount * _percentage / _percentageRate);
    }

    function paybackByTransfer(address to, uint256 amount) internal virtual validPercentage {
        IERC20LUXON(_tokenAddress).paybackByTransfer(to, amount * _percentage / _percentageRate);
    }
}

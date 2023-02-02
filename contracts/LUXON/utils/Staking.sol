// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC20LUXON.sol";

contract Staking is Ownable {
    struct StakingInfo {
        address tokenAddress;
        address contractAddress;
        uint256 percentageRate;
        uint256 percentage;
    }

    mapping (address => StakingInfo) stakingContractList;

    event AddStakingList(address tokenAddress, address contractAddress, uint256 percentageRate, uint256 percentage);

    constructor () {}

    function getStakingContractInfo(address _tokenAddress) public view returns (address, address, uint256, uint256) {
        StakingInfo memory staking = stakingContractList[_tokenAddress];
        return (
        staking.tokenAddress,
        staking.contractAddress,
        staking.percentageRate,
        staking.percentage
        );
    }

    function setStakingContract(StakingInfo[] memory _stakingList) external onlyOwner {
        for (uint256 i = 0; i < _stakingList.length; i++) {
            stakingContractList[_stakingList[i].tokenAddress] = _stakingList[i];
        }
    }

    function deleteStakingContract(address[] memory _tokenList) external onlyOwner {
        for (uint256 i = 0; i < _tokenList.length; i++) {
            delete stakingContractList[_tokenList[i]];
        }
    }
}

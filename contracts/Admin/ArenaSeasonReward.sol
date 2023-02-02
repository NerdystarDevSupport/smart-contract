// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "/contracts/LUXON/utils/ERC1155LUXON.sol";
import "/contracts/LUXON/utils/IERC20LUXON.sol";
import "/contracts/LUXON/utils/IERC721LUXON.sol";
import "/contracts/LUXON/utils/LuxOnLive.sol";
import "/contracts/Admin/data/ArenaSeasonRewardData.sol";

    error NOT_VALID_TOKEN_TYPE();

contract ArenaSeasonReward is Ownable, LuxOnLive {
    address private arenaSeasonRewardDataAddress;

    uint256 private startTimestamp;
    uint256 private periodTimestamp;

    address private rewardFrom;
    bool private isCalculate = false;

    constructor(
        address _arenaSeasonRewardDataAddress,
        uint256 _startTimestamp,
        uint256 _periodTimestamp,
        address _rewardFrom,
        address luxOnService
    ) LuxOnLive(luxOnService) {
        arenaSeasonRewardDataAddress = _arenaSeasonRewardDataAddress;
        startTimestamp = _startTimestamp;
        periodTimestamp = _periodTimestamp;
        if (_rewardFrom == address(0)) {
            rewardFrom = address(this);
        } else {
            rewardFrom = _rewardFrom;
        }
    }

    function getArenaSeasonRewardDataAddress() public view returns (address) {
        return arenaSeasonRewardDataAddress;
    }

    function getStartTimestamp() public view returns (uint256) {
        return startTimestamp;
    }

    function getPeriodTimestamp() public view returns (uint256) {
        return periodTimestamp;
    }

    function getNextCalculateTimestamp() public view returns (uint256) {
        return startTimestamp + periodTimestamp;
    }

    function getRewardFrom() public view returns (address) {
        return rewardFrom;
    }

    function getIsCalcuate() public view returns (bool) {
        return isCalculate;
    }

    function setArenaSeasonRewardDataAddress(address _arenaSeasonRewardDataAddress) external onlyOwner {
        arenaSeasonRewardDataAddress = _arenaSeasonRewardDataAddress;
    }

    function setStartTimestamp(uint256 _startTimestamp) external onlyOwner {
        startTimestamp = _startTimestamp;
    }

    function setPeriodTimestamp(uint256 _periodTimestamp) external onlyOwner {
        periodTimestamp = _periodTimestamp;
    }

    function setRewardFrom(address _rewardFrom) external onlyOwner {
        rewardFrom = _rewardFrom;
    }

    function setIsCalculate(bool _isCalculate) external onlyOwner {
        isCalculate = _isCalculate;
    }

    function dspSeasonCalculateRanking(bool isLast, ArenaSeasonRewardData.Rank[] memory _rankingInfo) external onlyOwner {
        require(getNextCalculateTimestamp() < block.timestamp, "not yet calcuate time");
        isCalculate = true;
        ArenaSeasonRewardData(arenaSeasonRewardDataAddress).seasonCalculateRanking(_rankingInfo);
        if (isLast) {
            isCalculate = false;
            startTimestamp = getNextCalculateTimestamp();
        }
    }

    function withdrawCalcuateReward() external isLive {
        require(!isCalculate, "calcuate time");
        uint256 rewardCount = ArenaSeasonRewardData(arenaSeasonRewardDataAddress).getRewardCount();
        uint256 index = 0;
        ArenaSeasonRewardData.SubRewardInfo[] memory subRewardInfos = new ArenaSeasonRewardData.SubRewardInfo[](rewardCount);
        address[] memory rewardTokenAddresses = ArenaSeasonRewardData(arenaSeasonRewardDataAddress).getRewardTokenAddresses();
        for (uint256 i = 0; i < rewardTokenAddresses.length; i++) {
            ArenaSeasonRewardData.TokenInfo memory tokenInfo = ArenaSeasonRewardData(arenaSeasonRewardDataAddress).getRewardTokenInfo(rewardTokenAddresses[i]);
            for (uint256 j = 0; j < tokenInfo.tokenIds.length; j++) {
                uint256 amount = ArenaSeasonRewardData(arenaSeasonRewardDataAddress).getUserPossibleReward(msg.sender, rewardTokenAddresses[i], tokenInfo.tokenIds[j]);
                if (amount != 0) {
                    subRewardInfos[index++] = ArenaSeasonRewardData.SubRewardInfo(rewardTokenAddresses[i], tokenInfo.tokenIds[j], amount);
                    if (ArenaSeasonRewardData.TokenType.ERC20 == tokenInfo.tokenType) {
                        IERC20LUXON(rewardTokenAddresses[i]).transferFrom(rewardFrom, msg.sender, amount);
                    } else if (ArenaSeasonRewardData.TokenType.ERC721 == tokenInfo.tokenType) {
                        IERC721LUXON(rewardTokenAddresses[i]).safeTransferFrom(rewardFrom, msg.sender, tokenInfo.tokenIds[j]);
                    } else if (ArenaSeasonRewardData.TokenType.ERC1155 == tokenInfo.tokenType) {
                        ERC1155LUXON(rewardTokenAddresses[i]).safeTransferFrom(rewardFrom, msg.sender, tokenInfo.tokenIds[j], amount, '');
                    } else {
                        revert NOT_VALID_TOKEN_TYPE();
                    }
                }
            }
        }
        ArenaSeasonRewardData.SubRewardInfo[] memory _subRewardInfos = new ArenaSeasonRewardData.SubRewardInfo[](index);
        for (uint256 i = 0; i < index; i++) {
            _subRewardInfos[i] = subRewardInfos[i];
        }
        ArenaSeasonRewardData(arenaSeasonRewardDataAddress).subUserRewardInfo(msg.sender, _subRewardInfos);
    }
}
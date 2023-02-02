// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../utils/SuperOperators.sol";

contract crystalStaking is SuperOperators, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Stake(address indexed from, uint256 tokenId, uint256 amount, uint256 timestamp);
    event UnStake(address indexed from, uint256 tokenId, uint256 amount, uint256 timestamp);
    event FundRewardToken(address indexed from, uint256 amount, uint256 timestamp);
    event RefundRewardToken(address indexed from, address indexed tokenAddress, uint256 amount, uint256 timestamp);
    event Claim(address indexed from, address indexed to, uint256 amount, uint256 timestamp);
    event LockUp(address indexed from, uint256 tokenId, uint256 amount, uint256 now, uint256 endAt);
    event DisabledLockUp(address indexed from, uint256 tokenId, uint256 amount, uint256 fee, uint256 timestamp);

    IERC20 public immutable rewardsToken;
    IERC1155 public immutable memorialCrystal;

    constructor(IERC1155 _memorialCrystal, IERC20 _rewardsToken) {
        memorialCrystal = _memorialCrystal;
        rewardsToken = _rewardsToken;
    }

    struct StakedToken {
        uint256 tokenId;
        uint256 amount;
        uint256 timestamp;
    }

    struct Staker {
        uint256 totalAmount;
        uint256 cumulativeAmount;
        StakedToken[] stakedTokens;
        uint256 timeOfLastUpdate;
        uint256 unclaimedRewards;
    }   

    struct UnStaker {
        uint256 tokenId;
        uint256 createAt;
        uint256 endAt;
        uint256 amount;
        uint256 totalTokenAmount;
    }

    uint256 private cumulativeFee;
    uint256 private lockUpFeePercentage = 10;
    uint256 private DAY = 86400;
    uint256 private lockupDayMinutes = 28 * DAY;
    uint256 private _lockupDay = 28;
    uint256 private rewardsPerPeriod = 0;
    uint256 private weeklySupply; // 시즌별 주간 공급량
    uint256 private noneToken = 99;
    uint256 private tokenTotalAmount;

    address[] private userList;
    uint256[] private tokenIds;
    
    mapping(address => Staker) public stakers;
    mapping(uint256 => address[]) stakingUsers;
    mapping(address => UnStaker[]) unStakers;

    function addStakeInfo(address _msgSender, uint256 _tokenId, uint256 _amount) private {
        stakers[_msgSender].totalAmount = stakers[_msgSender].totalAmount.add(_amount);
        stakers[_msgSender].stakedTokens.push(StakedToken(_tokenId, _amount, block.timestamp));
        stakers[_msgSender].timeOfLastUpdate = block.timestamp;
    }

    function stake(uint256 _tokenId, uint256 _amount) public nonReentrant {
        require(memorialCrystal.balanceOf(msg.sender, _tokenId) > _amount, "you require more memorial-crystal");
        require(0 != _amount, "invalid amount");

        bool exist = findUserByTokenId(msg.sender, _tokenId);
        if (false == exist) {
            stakingUsers[_tokenId].push(msg.sender);
        }

        if (0 == stakers[msg.sender].totalAmount) {
            userList.push(msg.sender);
        }
        addStakeInfo(msg.sender, _tokenId, _amount);
        tokenTotalAmount = tokenTotalAmount.add(_amount);

        memorialCrystal.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId,
            _amount,
            ""
        );

        emit Stake(msg.sender, _tokenId, _amount, block.timestamp);
    }

    function unStake(uint256 _tokenId, uint256 _amount) public nonReentrant {
        uint256 tokenIndex = getStakedTokenIndex(msg.sender, _tokenId);
        require(noneToken != tokenIndex, "not found token");
        require(0 != _amount, "invalid amount");

        uint256 refundAmount = stakers[msg.sender].stakedTokens[tokenIndex].amount;
        require(refundAmount.sub(_amount) >= 0, "More than the number of holdings");

        stakers[msg.sender].stakedTokens[tokenIndex].amount = stakers[msg.sender].stakedTokens[tokenIndex].amount.sub(_amount);
        stakers[msg.sender].totalAmount = stakers[msg.sender].totalAmount.sub(_amount);
        tokenTotalAmount = tokenTotalAmount.sub(_amount);

        if (0 == stakers[msg.sender].stakedTokens[tokenIndex].amount) {
            bool exist = findUserByTokenId(msg.sender, _tokenId);
            if (true == exist) {
                removeByValue(msg.sender, stakingUsers[_tokenId]);
            }
        }

        if (0 == stakers[msg.sender].totalAmount) {
            removeByValue(msg.sender, userList);
        }

        // lockup
        uint256 endAt = block.timestamp + lockupDayMinutes;
        unStakers[msg.sender].push(UnStaker(_tokenId, block.timestamp, endAt, _amount, stakers[msg.sender].totalAmount));

        emit UnStake(msg.sender, _tokenId, _amount, block.timestamp);
        emit LockUp(msg.sender, _tokenId, _amount, block.timestamp, endAt);
    }

    function claim(uint256 _index, bool disableLockup) public nonReentrant {
        if (0 < unStakers[msg.sender].length && disableLockup) {
            require(unStakers[msg.sender][_index].endAt < block.timestamp, "It's not time to get a reward yet.");

            uint256 subCumulativeAmount = stakers[msg.sender].cumulativeAmount.div(unStakers[msg.sender][_index].amount); // 100%
            stakers[msg.sender].cumulativeAmount = stakers[msg.sender].cumulativeAmount.sub(subCumulativeAmount);
            removeByIndexUnStaker(msg.sender, _index);

            memorialCrystal.safeTransferFrom(
                address(this),
                msg.sender,
                unStakers[msg.sender][_index].tokenId,
                unStakers[msg.sender][_index].amount,
                ""
            );
        }

        uint256 rewardValue = stakers[msg.sender].unclaimedRewards;
        if (0 < rewardValue) {
            stakers[msg.sender].unclaimedRewards = 0;
            stakers[msg.sender].timeOfLastUpdate = block.timestamp;

            rewardsToken.safeTransferFrom(
                address(this), 
                msg.sender, 
                rewardValue
            );
        }
    }

    function fundRewardToken(uint256 _amount) public onlySuperOperator nonReentrant {
        require(0 != _amount, "invalid amount");
        rewardsToken.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        emit FundRewardToken(msg.sender, _amount, block.timestamp);
    }

    function refundRewardToken(uint256 _amount) public  onlySuperOperator nonReentrant {
        uint256 balance = rewardsToken.balanceOf(address(this));
        require(balance.sub(_amount) >= 0, "over refund amount");

        rewardsToken.safeTransfer(
            msg.sender,
            _amount
        );

        emit RefundRewardToken(msg.sender, address(rewardsToken), _amount, block.timestamp);
    }

    function disabledLockUp(uint256[] memory _indexes) public {
        // 해제 비용 계산식
        // DSP 누적 정산량 / 언스테이킹 당시 토큰 전체 개수 / 락업 전체 일 수 * 락업 진행 일 수 / 10 * 언스테이킹 토큰 개수;

        for (uint i = 0; i < _indexes.length; i++) {
            UnStaker memory unstaker = unStakers[msg.sender][_indexes[i]];
            require(0 < unstaker.tokenId, "Error : Not exists tokenId");
            Staker memory staker = stakers[msg.sender];

            uint256 remainLockupTime = unstaker.endAt - unstaker.createAt;
            uint256 fee = staker.cumulativeAmount / unstaker.totalTokenAmount / _lockupDay * (remainLockupTime % DAY) / lockUpFeePercentage * unstaker.amount;

            uint256 subCumulativeAmount = staker.cumulativeAmount / unstaker.amount; // 100%
            stakers[msg.sender].cumulativeAmount = staker.cumulativeAmount.sub(subCumulativeAmount);

            if (0 < fee) {
                cumulativeFee = cumulativeFee.add(fee);
                rewardsToken.safeTransferFrom(
                    msg.sender, 
                    address(this), 
                    fee
                );
            }

            // 현재 시간으로 초기화
            unStakers[msg.sender][i].endAt = block.timestamp;

            emit DisabledLockUp(msg.sender, unStakers[msg.sender][_indexes[i]].tokenId, unStakers[msg.sender][_indexes[i]].amount, fee, block.timestamp);
        }
    }

    // required function to allow receiving ERC-1155
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
    external pure
    returns(bytes4)
    {
        operator;
        from;
        id;
        value;
        data;
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    // --------------------------------------------------------------------------------------------------------------------------------
    // 설정
    // get/set

    function setTokenId(uint256 _tokenId) public onlyOwner {
        tokenIds.push(_tokenId);
    }

    function setTokenIds(uint256[] memory _tokenIds) public onlyOwner {
        for(uint i = 0; i < _tokenIds.length; i++) {
            tokenIds.push(_tokenIds[i]);
        }
    }

    function setWeeklySupply(uint256 _amount) public onlyOwner {
        weeklySupply = _amount * 10 ** uint(18);
    }

    function setRewardsPerPeriod(uint256 _reward) public onlyOwner {
        rewardsPerPeriod = _reward;
    }

    function setLockUpDay(uint256 _day) public onlyOwner {
        lockupDayMinutes = _day * DAY;
        _lockupDay = _day;
    }

    function getLockUpDay() public view returns (uint256[] memory) {
        uint256[] memory data;
        data[0] = lockupDayMinutes;
        data[1] = _lockupDay;
        return data;
    }

    function getRewardsPerPeriod() public view returns (uint256) {
        return rewardsPerPeriod;
    }

    function getStakingUsers(uint256 _tokenId) public view returns (address[] memory) {
        return stakingUsers[_tokenId];
    }

    function getTokenIds() public view returns (uint256[] memory) {
        return tokenIds;
    }

    function getRewardTokenBalanceOf() public view returns (uint256) {
        return rewardsToken.balanceOf(address(this));
    }

    function getStakedTokenInfo() public view returns (StakedToken[] memory) {
        return stakers[msg.sender].stakedTokens;
    }

    function getUserList() public view returns (address[] memory) {
        return userList;
    }

    function getUnStakeList() public view returns (UnStaker[] memory) {
        return unStakers[msg.sender];
    }

    function getSeasonList() internal view returns (uint256[] memory) {
        return tokenIds;
    }

    function getWeeklySupply() public view returns (uint256) {
        return weeklySupply;
    }

    function setLockUpFee(uint256 _fee) public onlyOwner {
        lockUpFeePercentage = _fee;
    }

    function getLockUpFee() public view returns (uint256) {
        return lockUpFeePercentage;
    }

    function getDisableLockUpFee(uint256 _index) public view returns (uint256) {
        UnStaker memory unstaker = unStakers[msg.sender][_index];
        Staker memory staker = stakers[msg.sender];

        uint256 remainLockupTime = unstaker.endAt - unstaker.createAt;
        return staker.cumulativeAmount / unstaker.totalTokenAmount / _lockupDay * (remainLockupTime % DAY) / lockUpFeePercentage * unstaker.amount;
    }

    function getCumulativeFee() public view returns (uint256) {
        return cumulativeFee;
    }

    function getFee() public onlyOwner {
        require(0 != cumulativeFee);
        
        rewardsToken.safeTransferFrom(address(this), msg.sender, cumulativeFee);
        
        // init cumulativeFee
        cumulativeFee = 0;
    }

    function calculateRewards(address userAddr) internal view returns (uint256) {
        // (주간 보상량 / 28 / 현재 스테이킹 총 개수) * 유저 스테이킹 개수
        return (weeklySupply / rewardsPerPeriod / tokenTotalAmount) * stakers[userAddr].totalAmount;
    }

    // macro
    function updateUserReward() public onlyOwner {
        for (uint i = 0; i < userList.length; i++) {
            address userAddress = userList[i];
            if (address(0) == userAddress) {
                continue;
            }

            uint256 updateReward = calculateRewards(userAddress);
            stakers[userAddress].unclaimedRewards = stakers[userAddress].unclaimedRewards.add(updateReward);
            stakers[userAddress].cumulativeAmount = stakers[userAddress].cumulativeAmount.add(updateReward);
        }
    }

    // --------------------------------------------------------------------------------------------------------------------------------
    // 조회
    // private

    function findUserByTokenId(address userAddress, uint256 _tokenId) private view returns (bool) {
        address[] memory users = stakingUsers[_tokenId];
        for (uint i = 0; i < users.length; i++) {
            if (userAddress == users[i]) {
                return true;
            }
        }

        return false;
    }

    // 인덱스 찾기
    function getStakedTokenIndex(address msgSender, uint256 _tokenId) private view returns (uint256) {
        Staker memory staker = stakers[msgSender];
        for (uint256 i = 0; i < staker.stakedTokens.length; i++) {
            if (_tokenId == staker.stakedTokens[i].tokenId) {
                return i;
            }
        }

        return noneToken;
    }

    function findUserIndexByValue(address value, address[] storage list) private view returns(uint) {
        uint i = 0;
        while (list[i] != value && i <= list.length) {
            i++;
        }
        return i;
    }

    function removeByValue(address value, address[] storage list) private {
        uint i = findUserIndexByValue(value, list);
        if (i < list.length) {
            removeByIndex(i, list);
        }
    }

    function removeByIndex(uint i, address[] storage list) private {
        uint256 size = list.length;
        list[i] = list[size - 1];
        list.pop();
    }

    function removeByIndexUnStaker(address msgSender, uint256 index) private {
        uint256 size = unStakers[msgSender].length;
        unStakers[msgSender][index] = unStakers[msgSender][size - 1];
        unStakers[msgSender].pop();
    }
}

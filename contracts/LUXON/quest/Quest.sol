// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../utils/SuperOperators.sol";
import "../myPage/character/LCT.sol";
import "../../Admin/data/QuestData.sol";
import "../../Admin/data/CharacterData.sol";

contract Quest is SuperOperators, ReentrancyGuard {
    using SafeMath for uint256;

    event StartQuest(address indexed user, uint256 mission_no, uint256 start_time, uint256 end_time);
    event EnterQuest(address indexed user, uint256 mission_no, string eventName, uint256 timestamp);
    event ClearQuest(address indexed from, address indexed to, uint256 questNo, uint256 tokenId, uint256 amount);
    event CancelQuest(address indexed user);
    event DisabledStaking(address indexed user);
    event FundReward(address indexed user, uint256 tokenId, uint256 amount, uint256 timestamp);
    event ReFundReward(address indexed user, uint256 tokenId, uint256 amount, uint256 timestamp);

    struct QuestSlotInfo {
        uint256 tokenId;
        uint256 amount;
        bool isValid;
        uint256 createdAt;
    }

    struct QuestBox {
        mapping(uint256 => QuestInfo) quest;
        uint256 questSize;
    }

    struct QuestInfo {
        uint256 questNo;
        uint256 slotDataSize;
        uint256 createAt;
        uint256 startAt;
        uint256 endAt;
        bool isGetReward;
        mapping(uint256 => QuestSlotInfo) slotData;
    }

    struct StakeInfo {
        uint256 tokenId;
        uint256 amount;
        uint256 conditionType;
    }

    struct QuestDataOutDto {
        uint256 questNo;
        string name;
        uint256 mainQuestGroup;
        uint256 subQuestGroup;
        uint256 questCategory;
        uint256 stakingTime;
        uint256 reward;
        uint256 rewardAmount;
        uint256 nextQuest;
        uint256 createAt;
        uint256 startAt;
        uint256 endAt;
        bool isGetReward;
        QuestSlotInfo[] slotData;
    }

    struct FundRewardDto {
        uint256 tokenId;
        uint256 amount;
    }

    address private questDataContract;
    address private characterContract;
    address private gachaTicketContract;
    address private dspCharacterData;
    address burnAddress = 0x0000000000000000000000000000000000000000;

    uint256 errorNo = 9999;
    uint256 private DAY = 86400;
    uint256 private HOUR = 3600;

    mapping(address => QuestBox) userQuestInfo;
    mapping(address => uint256[]) userQuestClearInfo;
    mapping(address => mapping(uint256 => StakeInfo[])) userStakeInfo; // <userAddr, <questNo, StakeData[]>>

    constructor(
        address _questDataContract,
        address _characterContract,
        address _gachaTicketContract,
        address _dspCharacterDataContract
    ) {
        questDataContract = _questDataContract;
        characterContract = _characterContract;
        gachaTicketContract = _gachaTicketContract;
        dspCharacterData = _dspCharacterDataContract;
    }
    
    function getQuestList(uint256 _startCount, uint256 _endCount) public view returns (QuestData.Quest[] memory) {
        return QuestData(questDataContract).getQuests(_startCount, _endCount);
    }

    function getQuest(uint256 _questNo) public view returns (QuestData.Quest memory) {
        return QuestData(questDataContract).getQuest(_questNo);
    }

    function enterQuest(uint256 _questNo, uint256[] memory _tokenIds) public nonReentrant {
        // Data
        QuestData.Quest memory questData = QuestData(questDataContract).getQuest(_questNo);
        uint256 questGroup = questData.mainQuestGroup;
        QuestInfo storage qi = userQuestInfo[msg.sender].quest[questGroup];

        if (0 == qi.questNo) {
            initQuest(msg.sender, questData);
        }

        // check mission duplicated
        require(true != qi.isGetReward, "You haven't been rewarded yet.");

        // check mission condition
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (0 == _tokenIds[i]) {
                continue;
            }

            string memory name = LCT(characterContract).getCharacterInfo(_tokenIds[i]);
            (uint256 _tier, , , , , uint256 _rootId, ) = DspCharacterData(dspCharacterData).getCharacterInfo(name);

            // 현재 캐릭터가 조건에 맞는지 체크
            if (uint256(QuestData.ConditionType.CHARACTER) == questData.questConditionSlot[i].conditionType) {
                require(uint256(_rootId) == uint256(questData.questConditionSlot[i].conditionValue), "Invalid Condition : This character does not match the condition");
            } else if (uint256(QuestData.ConditionType.CHARACTER_TIER) == questData.questConditionSlot[i].conditionType) {
                require(uint256(_tier) == uint256(questData.questConditionSlot[i].conditionValue), "Invalid Condition : This character does not match the tier conditions.");
            }

            // 나중에 list에 담아서 한번에 transfer 실행
            checkConditionAndTransfer(msg.sender, _questNo, _tokenIds[i], questData.questConditionSlot[i], i, questGroup);
        }

        // 미션 진행 가능한지 유효성 검사
        uint256 successCount = 0;
        for (uint256 i = 0; i < qi.slotDataSize; i++) {
            if (true == userQuestInfo[msg.sender].quest[questGroup].slotData[i].isValid) {
                successCount++;
            }

            if (qi.slotDataSize == successCount) {
                startQuest(msg.sender, _questNo, questData.stakingTime, questData);
            }
        }

        emit EnterQuest(msg.sender, _questNo, questData.name, block.timestamp);
    }

    function clearQuest(uint256 _questNo) public nonReentrant {
        QuestData.Quest memory questData = QuestData(questDataContract).getQuest(_questNo);
        uint256 questGroup = questData.mainQuestGroup;
        uint256 rewardId = questData.reward;
        uint256 amount = questData.rewardAmount;

        // 클리어 리스트에 저장
        for (uint256 i = 0; i < userQuestClearInfo[msg.sender].length; i++) {
            require(userQuestClearInfo[msg.sender][i] != _questNo, "Error : Already cleared mission");            
        }
        userQuestClearInfo[msg.sender].push(_questNo);

        // 보상 받았다 체크
        userQuestInfo[msg.sender].quest[questGroup].isGetReward = true;

        // 보상 주고
        IERC1155(gachaTicketContract).safeTransferFrom(
            address(this),
            msg.sender,
            rewardId,
            amount,
            ""
        );

        // 스테이킹한 토큰 돌려주고
        for (uint256 i = 0; i < userStakeInfo[msg.sender][_questNo].length; i++) {
            uint256 tokenId = userStakeInfo[msg.sender][_questNo][i].tokenId;
            _transferFromByType(address(this), msg.sender, tokenId, userStakeInfo[msg.sender][_questNo][i].amount, userStakeInfo[msg.sender][_questNo][i].conditionType);
        }

        // 스테이킹 데이터 지우고
        delete userStakeInfo[msg.sender][_questNo];

        if (0 < questData.nextQuest) {
            reNewMission(questData.nextQuest);
        }

        emit ClearQuest(address(this), msg.sender, _questNo, rewardId, amount);
    }

    function getNewQuest(uint256 _currentQuestNo) public nonReentrant {
        QuestData.Quest memory questData = QuestData(questDataContract).getQuest(_currentQuestNo);
        uint256 questGroup = questData.mainQuestGroup;

        require(true == userQuestInfo[msg.sender].quest[questGroup].isGetReward, "You haven't cleared the previous quest yet.");

        reNewMission(questData.nextQuest);
    }

    // 취소
    function cancelQuest(uint256 _questNo) public nonReentrant {
        QuestData.Quest memory questData = QuestData(questDataContract).getQuest(_questNo);
        uint256 questGroup = questData.mainQuestGroup;
        userQuestInfo[msg.sender].quest[questGroup].startAt = 0;
        userQuestInfo[msg.sender].quest[questGroup].endAt = 0;
        
        for (uint256 i = 0; i < userQuestInfo[msg.sender].quest[questGroup].slotDataSize; i++) {
            userQuestInfo[msg.sender].quest[questGroup].slotData[i].tokenId = 0;
            userQuestInfo[msg.sender].quest[questGroup].slotData[i].isValid = false;
            userQuestInfo[msg.sender].quest[questGroup].slotData[i].createdAt = 0;
            userQuestInfo[msg.sender].quest[questGroup].slotData[i].amount = 0;
        }

        // // <userAddr, <questNo, StakeInfo[]>>
        for (uint256 i = 0; i < userStakeInfo[msg.sender][_questNo].length; i++) {
            uint256 tokenId = userStakeInfo[msg.sender][_questNo][i].tokenId;
            uint256 amount = userStakeInfo[msg.sender][_questNo][i].amount;
            uint256 _type = userStakeInfo[msg.sender][_questNo][i].conditionType;

            _transferFromByType(address(this), msg.sender, tokenId, amount, _type);
        }

        emit CancelQuest(msg.sender);
    }

    // 해제 / 교체
    function disabledStaking(uint256 _questNo, uint256[] calldata _tokenIds) public nonReentrant {
        QuestData.Quest memory questData = QuestData(questDataContract).getQuest(_questNo);
        uint256 questGroup = questData.mainQuestGroup;
        QuestInfo storage qi = userQuestInfo[msg.sender].quest[questGroup];

        require(_questNo == qi.questNo, "Invalid Parameter : Unmatched quest No");
        
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (0 < qi.slotData[i].tokenId) {

                _transferFromByType(address(this), msg.sender, qi.slotData[i].tokenId, qi.slotData[i].amount, questData.questConditionSlot[i].conditionType);
                
            }

            if (0 < _tokenIds[i]) {

                checkConditionAndTransfer(msg.sender, _questNo, _tokenIds[i], questData.questConditionSlot[i], i, questGroup);

            } else {

                qi.slotData[i].tokenId = _tokenIds[i];
                qi.slotData[i].createdAt = 0;
                qi.slotData[i].isValid = false;
                qi.slotData[i].amount = 0;

            }
        }

        emit DisabledStaking(msg.sender);
    }

    function reNewMission(uint256 _questNo) private {
        QuestData.Quest memory questData = QuestData(questDataContract).getQuest(_questNo);
        uint256 questGroup = questData.mainQuestGroup;
        QuestInfo storage qi = userQuestInfo[msg.sender].quest[questGroup];

        for (uint256 i = 0; i < questData.questConditionSlot.length; i++) {
            qi.slotData[qi.slotDataSize] = QuestSlotInfo(0, 0, false, block.timestamp);
            qi.slotDataSize++;
        }
        qi.questNo = _questNo;
        qi.createAt = block.timestamp;
        qi.startAt = 0;
        qi.endAt = 0;
        qi.isGetReward = false;
    }

    function _transferFromByType(address _from, address _to, uint256 _tokenId, uint256 _amount, uint256 _conditionType) private {
        // ERC721
        if (uint256(QuestData.ConditionType.CHARACTER) == _conditionType || uint256(QuestData.ConditionType.CHARACTER_TIER) == _conditionType) {
            IERC721(characterContract).transferFrom(_from, _to, _tokenId);
        } else if (uint256(QuestData.ConditionType.PACK) == _conditionType) { // ERC1155
            IERC1155(gachaTicketContract).safeTransferFrom(_from, _to, _tokenId, _amount, "");
        }
    }

    function startQuest(address _msgSender, uint256 _questNo, uint256 _period, QuestData.Quest memory _questData) private {
        uint256 questGroup = _questData.mainQuestGroup;

        userQuestInfo[_msgSender].quest[questGroup].startAt = block.timestamp;
        uint256 endAt = HOUR.mul(_period);
        userQuestInfo[_msgSender].quest[questGroup].endAt = block.timestamp.add(endAt);

        emit StartQuest(_msgSender, _questNo, block.timestamp, block.timestamp.add(endAt));
    }

    function checkConditionAndTransfer(address _msgSender, uint256 _questNo, uint256 _tokenId, QuestData.QuestConditionSlot memory _questConditionSlot, uint256 _index, uint256 _questGroup) private {
        uint256 conditionType = _questConditionSlot.conditionType;
        uint256 questType = _questConditionSlot.questType;
        uint256 amount = _questConditionSlot.conditionAmount;

        if (uint256(QuestData.MissionType.STAKE) == questType) {
            _transferFromByType(_msgSender, address(this), _tokenId, amount, conditionType);
            
            userStakeInfo[_msgSender][_questNo].push(StakeInfo(_tokenId, amount, conditionType)); // tokenId, amount, conditionType

        } else if (uint256(QuestData.MissionType.BURN) == questType) {
            _transferFromByType(_msgSender, address(burnAddress), _tokenId, amount, conditionType);

        } else if (uint256(QuestData.MissionType.REGIST) == questType) {
            _transferFromByType(_msgSender, address(this), _tokenId, amount, conditionType);

            userStakeInfo[_msgSender][_questNo].push(StakeInfo(_tokenId, amount, conditionType));
        }

        userQuestInfo[_msgSender].quest[_questGroup].slotData[_index].tokenId = _tokenId;
        userQuestInfo[_msgSender].quest[_questGroup].slotData[_index].amount = userQuestInfo[_msgSender].quest[_questGroup].slotData[_index].amount.add(amount);

        if (userQuestInfo[_msgSender].quest[_questGroup].slotData[_index].amount == _questConditionSlot.conditionAmount) {
            userQuestInfo[_msgSender].quest[_questGroup].slotData[_index].isValid = true;
        }
    }

    function initQuest(address _msgSender, QuestData.Quest memory _questData) private {
        uint256 questGroup = _questData.mainQuestGroup;

        for (uint256 i = 0; i < _questData.questConditionSlot.length; i++) {
            userQuestInfo[_msgSender].quest[questGroup].slotData[userQuestInfo[_msgSender].quest[questGroup].slotDataSize] = QuestSlotInfo(0, 0, false, block.timestamp);
            userQuestInfo[_msgSender].quest[questGroup].slotDataSize++;    
        }
        userQuestInfo[_msgSender].quest[questGroup].questNo = _questData.questNo;
        userQuestInfo[_msgSender].quest[questGroup].createAt = block.timestamp;
        userQuestInfo[_msgSender].quest[questGroup].startAt = 0;
        userQuestInfo[_msgSender].quest[questGroup].endAt = 0;
        userQuestInfo[_msgSender].quest[questGroup].isGetReward = false;
        userQuestInfo[_msgSender].questSize++;
    }

    function fundReward(FundRewardDto[] calldata _fundReward) public onlySuperOperator nonReentrant {
        for (uint256 i = 0; i < _fundReward.length; i++) {
            IERC1155(gachaTicketContract).safeTransferFrom(
                msg.sender, 
                address(this), 
                _fundReward[i].tokenId, 
                _fundReward[i].amount, 
                ""
            );

            emit FundReward(msg.sender, _fundReward[i].tokenId, _fundReward[i].amount, block.timestamp);
        }
    }

    function reFundReward(FundRewardDto[] calldata _reFundReward) public onlySuperOperator nonReentrant {
        for (uint256 i = 0; i < _reFundReward.length; i++) {
            IERC1155(gachaTicketContract).safeTransferFrom(
                address(this),
                msg.sender, 
                _reFundReward[i].tokenId, 
                _reFundReward[i].amount, 
                ""
            );

            emit ReFundReward(msg.sender, _reFundReward[i].tokenId, _reFundReward[i].amount, block.timestamp);
        }
    }

    //////// getter, setter ////////
    function getQuestDataContract() public view returns (address) {
        return questDataContract;
    }

    function setQuestDataContract(address _questDataContract) public onlyOwner {
        questDataContract = _questDataContract;
    }

    function getCharacterContract() public view returns (address) {
        return characterContract;
    }

    function setCharacterContract(address _characterContract) public onlyOwner {
        characterContract = _characterContract;
    }

    function getDspCharacterData() public view returns (address) {
        return dspCharacterData;
    }

    function setDspCharacterData(address _dspCharacterData) public onlyOwner {
        dspCharacterData = _dspCharacterData;
    }

    function getClearQuestList() public view returns (uint256[] memory) {
        return userQuestClearInfo[msg.sender];
    }

    function getStakingInfo(uint256 questNo) public view returns (StakeInfo[] memory) {
        return userStakeInfo[msg.sender][questNo];
    }

    function getQuestInfo() public view returns (QuestDataOutDto[] memory) {
        QuestBox storage questBox = userQuestInfo[msg.sender];
        QuestDataOutDto[] memory info = new QuestDataOutDto[](questBox.questSize);
        uint256 count = 0;

        for (uint256 i = 1; i <= questBox.questSize; i++) {
            QuestData.Quest memory questData = QuestData(questDataContract).getQuest(questBox.quest[i].questNo);
            QuestSlotInfo[] memory slotData = new QuestSlotInfo[](questBox.quest[i].slotDataSize);

            for (uint j = 0; j < questBox.quest[i].slotDataSize; j++) {
                slotData[j] = questBox.quest[i].slotData[j];
            }

            info[count] = QuestDataOutDto(
                questBox.quest[i].questNo,
                questData.name,
                questData.mainQuestGroup,
                questData.subQuestGroup,
                questData.questCategory,
                questData.stakingTime,
                questData.reward,
                questData.rewardAmount,
                questData.nextQuest,
                questBox.quest[i].createAt,
                questBox.quest[i].startAt,
                questBox.quest[i].endAt,
                questBox.quest[i].isGetReward,
                slotData
            );
            count++;
        }

        return info;
    }

    function getRewardBalance(uint256[] calldata _tokenIds) public view returns (FundRewardDto[] memory) {
        FundRewardDto[] memory fundRewardDto = new FundRewardDto[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 balance = IERC1155(gachaTicketContract).balanceOf(address(this), _tokenIds[i]);
            fundRewardDto[i] = FundRewardDto(_tokenIds[i], balance);
        }
        
        return fundRewardDto;
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
}
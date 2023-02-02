// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "/contracts/Admin/data/CharacterData.sol";
import "/contracts/Admin/data/GachaData.sol";
import "/contracts/LUXON/utils/ILuxOnCharacter.sol";

contract GachaMachine is Ownable {
    event SetGachaDataAddress(address indexed gachaDataAddress);
    event SetCharacterDataAddress(address indexed characterDataAddress);
    event SetCharacterTokenAddress(address indexed characterTokenAddress);
    event GachaActor(address indexed userAddrss, uint256 indexed gachaTokenId, uint256 actorTokenId, string name);

    address private gachaDataAddress;
    address private characterDataAddress;
    address private characterTokenAddress;

    constructor(
        address _gachaDataAddress,
        address _characterDataAddress,
        address _characterTokenAddress
    ) {
        gachaDataAddress = _gachaDataAddress;
        characterDataAddress = _characterDataAddress;
        characterTokenAddress = _characterTokenAddress;
    }

    struct Gacha {
        uint256 gachaTokenId;
        RandomSeed[] randomSeed;
    }

    struct RandomSeed {
        address userAddress;
        uint256 actorTokenId;
        bytes32 seed;
    }

    struct GachaSimulator {
        uint256 gachaTokenId;
        bytes32[] seed;
    }

    function getGachaDataAddress() public view returns (address) {
        return gachaDataAddress;
    }

    function getCharacterDataAddress() public view returns (address) {
        return characterDataAddress;
    }

    function getCharacterTokenAddress() public view returns (address) {
        return characterTokenAddress;
    }

    function setGachaDataAddress(address _gachaDataAddress) external onlyOwner {
        gachaDataAddress = _gachaDataAddress;
        emit SetGachaDataAddress(_gachaDataAddress);
    }

    function setCharacterDataAddress(address _characterDataAddress) external onlyOwner {
        characterDataAddress = _characterDataAddress;
        emit SetCharacterDataAddress(_characterDataAddress);
    }

    function setCharacterTokenAddress(address _characterTokenAddress) external onlyOwner {
        characterTokenAddress = _characterTokenAddress;
        emit SetCharacterTokenAddress(_characterTokenAddress);
    }

    function gachaActor(Gacha[] memory _gacha) external onlyOwner {
        uint256 sum = 0;
        uint256 characterIndex = 0;
        for (uint256 i = 0; i < _gacha.length; i++) {
            sum += _gacha[i].randomSeed.length;
        }
        ILuxOnCharacter.Character[] memory _character = new ILuxOnCharacter.Character[](sum);
        for (uint256 i = 0; i < _gacha.length; i++) {
            (uint256[] memory _tierRatio, uint256 _tierRatioSum) = DspGachaData(gachaDataAddress).getGachaTierRatio(_gacha[i].gachaTokenId);
            (uint256[][] memory _gachaGradeRatio, uint256[] memory _gachaGradeRatioSum) = DspGachaData(gachaDataAddress).getGachaGachaGradeRatio(_gacha[i].gachaTokenId);
            for (uint256 j = 0; j < _gacha[i].randomSeed.length; j++) {
                uint256 _tier = randomNumber(
                    _gacha[i].randomSeed[j].seed,
                    _gacha[i].randomSeed[j].actorTokenId,
                    _tierRatio,
                    _tierRatioSum,
                    "tier"
                );
                uint256 _gachaGrade = randomNumber(
                    _gacha[i].randomSeed[j].seed,
                    _gacha[i].randomSeed[j].actorTokenId,
                    _gachaGradeRatio[_tier],
                    _gachaGradeRatioSum[_tier],
                    "gacha_grade"
                );

                uint index = uint(keccak256(abi.encodePacked(_gacha[i].randomSeed[j].seed, _gacha[i].randomSeed[j].actorTokenId, "index"))) %
                DspCharacterData(characterDataAddress).getCharacterCountByTireAndGachaGrade(_tier + 1, _gachaGrade + 1);

                _character[characterIndex] = ILuxOnCharacter.Character(
                    _gacha[i].randomSeed[j].actorTokenId,
                    DspCharacterData(characterDataAddress).getCharacterInfoByTireAndIndex(_tier + 1, _gachaGrade + 1, index)
                );
                emit GachaActor(_gacha[i].randomSeed[j].userAddress, _gacha[i].gachaTokenId, _gacha[i].randomSeed[j].actorTokenId, _character[characterIndex].name);
                characterIndex++;
            }
        }
        ILuxOnCharacter(characterTokenAddress).setCharacterName(_character);
    }

    function gachaActorSimulator(GachaSimulator memory _gacha) public view returns (string[] memory) {
        uint256 characterIndex = 0;
        string[] memory _characterName = new string[](_gacha.seed.length);
        (uint256[] memory _tierRatio, uint256 _tierRatioSum) = DspGachaData(gachaDataAddress).getGachaTierRatio(_gacha.gachaTokenId);
        (uint256[][] memory _gachaGradeRatio, uint256[] memory _gachaGradeRatioSum) = DspGachaData(gachaDataAddress).getGachaGachaGradeRatio(_gacha.gachaTokenId);
        for (uint256 j = 0; j < _gacha.seed.length; j++) {
            uint256 _tier = randomNumber(_gacha.seed[j], j, _tierRatio, _tierRatioSum, "tier");
            uint256 _gachaGrade = randomNumber(_gacha.seed[j], j, _gachaGradeRatio[_tier], _gachaGradeRatioSum[_tier], "gacha_grade");

            uint index = uint(keccak256(abi.encodePacked(_gacha.seed[j], j, "index"))) %
            DspCharacterData(characterDataAddress).getCharacterCountByTireAndGachaGrade(_tier + 1, _gachaGrade + 1);
            _characterName[characterIndex++] = DspCharacterData(characterDataAddress).getCharacterInfoByTireAndIndex(_tier + 1, _gachaGrade + 1, index);
        }
        return _characterName;
    }

    function randomNumber(bytes32 _seed, uint256 _tokenId, uint256[] memory _ratio, uint256 _ratioSum, string memory _type) private pure returns (uint256 index) {
        uint ratio = uint(keccak256(abi.encodePacked(_seed, _tokenId, _type))) % _ratioSum;
        index = 0;
        uint ratioSum = 0;
        for (uint256 i = 0; i < _ratio.length; i++) {
            ratioSum += _ratio[i];
            if (ratio <= ratioSum) {
                break;
            }
            index++;
        }
    }
}
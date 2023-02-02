// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "/contracts/LUXON/utils/ERC1155LUXON.sol";
import "/contracts/Admin/data/ValueChipData.sol";
import "/contracts/Admin/data/AirdropUser.sol";
import "/contracts/LUXON/utils/LuxOnLive.sol";

contract AirdropValueChip is Ownable, LuxOnLive {

    event SetMintAddress(address[] indexed mintAddress);
    event SetValueChipDataAddress(address indexed valueChipDataAddress);
    event SetAirdropUserAddress(address indexed airdropUserAddress);
    event SetAirdropRemainCount(uint256 indexed tokenId, uint256 indexed limit);
    event Airdrop(address indexed to, address indexed mintAddress, uint256 indexed tokenId, uint256 amount, uint256 round, bytes32[] airdropUserProof);

    address[] private mintAddress;
    address private valueChipDataAddress;
    address private airdropUserAddress;

    // token id => remain count
    mapping(uint256 => uint256) private airdropLimit;

    constructor(
        address[] memory _mintAddress,
        address _valueChipDataAddress,
        address _airdropUserAddress,
        address luxOnService
    ) LuxOnLive(luxOnService) {
        mintAddress = _mintAddress;
        valueChipDataAddress = _valueChipDataAddress;
        airdropUserAddress = _airdropUserAddress;
    }

    struct AirdopInfo {
        address to;
        address valueChipAddress;
        uint256 tokenId;
        uint256 amount;
        uint256 round;
        bytes32[] airdropUserProof;
    }

    function getAirdropRemainCount(uint256 _tokenId) public view returns (uint256) {
        return airdropLimit[_tokenId];
    }

    function getMintAddress() public view returns (address[] memory) {
        return mintAddress;
    }

    function getValueChipDataAddress() public view returns (address) {
        return valueChipDataAddress;
    }

    function getAirdropUserAddress() public view returns (address) {
        return airdropUserAddress;
    }

    function setMintAddress(address[] memory _mintAddress) external onlyOwner {
        mintAddress = _mintAddress;
        emit SetMintAddress(_mintAddress);
    }

    function setValueChipDataAddress(address _valueChipDataAddress) external onlyOwner {
        valueChipDataAddress = _valueChipDataAddress;
        emit SetValueChipDataAddress(_valueChipDataAddress);
    }

    function setAirdropUserAddress(address _airdropUserAddress) external onlyOwner {
        airdropUserAddress = _airdropUserAddress;
        emit SetAirdropUserAddress(_airdropUserAddress);
    }

    function setAirdropRemainCount(uint256 _tokenId, uint256 _amount) external onlyOwner {
        airdropLimit[_tokenId] = _amount;
        emit SetAirdropRemainCount(_tokenId, airdropLimit[_tokenId]);
    }

    function addAirdropRemainCount(uint256 _tokenId, uint256 _amount) external onlyOwner {
        airdropLimit[_tokenId] += _amount;
        emit SetAirdropRemainCount(_tokenId, airdropLimit[_tokenId]);
    }

    function subAirdropRemainCount(uint256 _tokenId, uint256 _amount) external onlyOwner {
        airdropLimit[_tokenId] -= _amount;
        emit SetAirdropRemainCount(_tokenId, airdropLimit[_tokenId]);
    }

    function airdrop(AirdopInfo memory airdopInfo) external onlyOwner {
        require(airdropLimit[airdopInfo.tokenId] >= airdopInfo.amount, "total: The number of air drops is insufficient.");
        airdropLimit[airdopInfo.tokenId] -= airdopInfo.amount;
        AirdropUser(airdropUserAddress).airdrop(AirdropUser.AirdropUserInfo(airdopInfo.to, airdopInfo.valueChipAddress, airdopInfo.tokenId, airdopInfo.amount, airdopInfo.round, airdopInfo.airdropUserProof));
        ERC1155LUXON(airdopInfo.valueChipAddress).mint(airdopInfo.to, airdopInfo.tokenId, airdopInfo.amount, '');

        emit Airdrop(airdopInfo.to, airdopInfo.valueChipAddress, airdopInfo.tokenId, airdopInfo.amount, airdopInfo.round, airdopInfo.airdropUserProof);
    }

    function airdropMany(AirdopInfo[] memory airdopInfo) external onlyOwner {
        for (uint256 i = 0; i < airdopInfo.length; i++) {
            require(airdropLimit[airdopInfo[i].tokenId] >= airdopInfo[i].amount, "total: The number of air drops is insufficient.");
            airdropLimit[airdopInfo[i].tokenId] -= airdopInfo[i].amount;
            AirdropUser(airdropUserAddress).airdrop(AirdropUser.AirdropUserInfo(airdopInfo[i].to, airdopInfo[i].valueChipAddress, airdopInfo[i].tokenId, airdopInfo[i].amount, airdopInfo[i].round, airdopInfo[i].airdropUserProof));
            ERC1155LUXON(airdopInfo[i].valueChipAddress).mint(airdopInfo[i].to, airdopInfo[i].tokenId, airdopInfo[i].amount, '');
            emit Airdrop(airdopInfo[i].to, airdopInfo[i].valueChipAddress, airdopInfo[i].tokenId, airdopInfo[i].amount, airdopInfo[i].round, airdopInfo[i].airdropUserProof);
        }
    }
}
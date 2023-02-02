// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "/contracts/LUXON/utils/ERC1155LUXON.sol";
import "/contracts/Admin/data/GachaData.sol";
import "/contracts/Admin/data/AirdropUser.sol";
import "/contracts/LUXON/utils/LuxOnLive.sol";

contract AirdropGachaTicket is Ownable, LuxOnLive {

    event SetMintAddress(address indexed mintAddress);
    event SetGachaDataAddress(address indexed gachaDataAddress);
    event SetAirdropUserAddress(address indexed airdropUserAddress);
    event SetAirdropRemainCount(uint256 indexed tokenId, uint256 indexed limit);
    event Airdrop(address indexed to, address indexed mintAddress, uint256 indexed tokenId, uint256 amount, uint256 round, bytes32[] airdropUserProof);

    address private mintAddress;
    address private gachaDataAddress;
    address private airdropUserAddress;

    // token id => remain count
    mapping(uint256 => uint256) private airdropLimit;

    constructor(
        address _mintAddress,
        address _gachaDataAddress,
        address _airdropUserAddress,
        address luxOnService
    ) LuxOnLive(luxOnService) {
        mintAddress = _mintAddress;
        gachaDataAddress = _gachaDataAddress;
        airdropUserAddress = _airdropUserAddress;
    }

    struct AirdopInfo {
        address to;
        uint256 tokenId;
        uint256 amount;
        uint256 round;
        bytes32[] airdropUserProof;
    }

    function getAirdropRemainCount(uint256 _tokenId) public view returns (uint256) {
        return airdropLimit[_tokenId];
    }

    function getMintAddress() public view returns (address) {
        return mintAddress;
    }

    function getGachaDataAddress() public view returns (address) {
        return gachaDataAddress;
    }

    function getAirdropUserAddress() public view returns (address) {
        return airdropUserAddress;
    }

    function setMintAddress(address _mintAddress) external onlyOwner {
        mintAddress = _mintAddress;
        emit SetMintAddress(_mintAddress);
    }

    function setGachaDataAddress(address _gachaDataAddress) external onlyOwner {
        gachaDataAddress = _gachaDataAddress;
        emit SetGachaDataAddress(_gachaDataAddress);
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
        AirdropUser(airdropUserAddress).airdrop(AirdropUser.AirdropUserInfo(airdopInfo.to, mintAddress, airdopInfo.tokenId, airdopInfo.amount, airdopInfo.round, airdopInfo.airdropUserProof));
        DspGachaData.GachaInfo memory _gachaInfo = DspGachaData(gachaDataAddress).getGachaInfo(airdopInfo.tokenId);
        require(_gachaInfo.isValid, "not valid token id");
        ERC1155LUXON(mintAddress).mint(airdopInfo.to, airdopInfo.tokenId, airdopInfo.amount, '');

        emit Airdrop(airdopInfo.to, mintAddress, airdopInfo.tokenId, airdopInfo.amount, airdopInfo.round, airdopInfo.airdropUserProof);
    }

    function airdropMany(AirdopInfo[] memory airdopInfo) external onlyOwner {
        for (uint256 i = 0; i < airdopInfo.length; i++) {
            require(airdropLimit[airdopInfo[i].tokenId] >= airdopInfo[i].amount, "total: The number of air drops is insufficient.");
            airdropLimit[airdopInfo[i].tokenId] -= airdopInfo[i].amount;
            AirdropUser(airdropUserAddress).airdrop(AirdropUser.AirdropUserInfo(airdopInfo[i].to, mintAddress, airdopInfo[i].tokenId, airdopInfo[i].amount, airdopInfo[i].round, airdopInfo[i].airdropUserProof));
            DspGachaData.GachaInfo memory _gachaInfo = DspGachaData(gachaDataAddress).getGachaInfo(airdopInfo[i].tokenId);
            require(_gachaInfo.isValid, "not valid token id");
            ERC1155LUXON(mintAddress).mint(airdopInfo[i].to, airdopInfo[i].tokenId, airdopInfo[i].amount, '');
            emit Airdrop(airdopInfo[i].to, mintAddress, airdopInfo[i].tokenId, airdopInfo[i].amount, airdopInfo[i].round, airdopInfo[i].airdropUserProof);
        }
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "/contracts/LUXON/utils/ERC1155LUXON.sol";
import "/contracts/Admin/data/ValueChipData.sol";

contract HeroValueChip is ERC1155LUXON {

    address private valueChipDataAddress;
    DspValueChipData.ValueChipsType private valueChipType = DspValueChipData.ValueChipsType.Hero;

    constructor(
        address _valueChipDataAddress,
        string memory operator,
        address luxOnAdmin
    ) ERC1155LUXON("Desperado: Value Chip", "Hero", '', operator, luxOnAdmin) {
        valueChipDataAddress = _valueChipDataAddress;
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) external override onlySuperOperator {
        require(DspValueChipData(valueChipDataAddress).getValueChipValueChipsType(id) == uint32(valueChipType), "not valid value chip type");
        require(DspValueChipData(valueChipDataAddress).getValueChipsIsValid(id), "not valid token id");
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external override onlySuperOperator {
        for (uint256 i = 0; i < ids.length; i++) {
            require(DspValueChipData(valueChipDataAddress).getValueChipValueChipsType(ids[i]) == uint32(valueChipType), "not valid value chip type");
            require(DspValueChipData(valueChipDataAddress).getValueChipsIsValid(ids[i]), "not valid token id");
        }
        _mintBatch(to, ids, amounts, data);
    }

    function getValueChipType() public view returns (uint32) {
        return uint32(valueChipType);
    }
}
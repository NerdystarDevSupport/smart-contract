// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "/contracts/LUXON/utils/ERC1155LUXON.sol";

contract GachaTicket is ERC1155LUXON {
    constructor(
        string memory operator,
        address luxOnAdmin
    ) ERC1155LUXON("Dsp-Gacha-Tickey", "DGT", '', operator, luxOnAdmin) {}
}
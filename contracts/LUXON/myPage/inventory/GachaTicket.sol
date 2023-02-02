// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../../utils/ERC1155LUXON.sol";

contract GachaTicket is ERC1155LUXON {
    constructor(
        string memory operator,
        address luxOnAdmin
    ) ERC1155LUXON("Desperado: Hero Gacha", "Gacha", '', operator, luxOnAdmin) {}
}
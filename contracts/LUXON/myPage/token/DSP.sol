// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../utils/ERC20LUXON.sol";

contract Dsp is ERC20LUXON {
    constructor(
        string memory operator,
        address luxOnAdmin
    ) ERC20LUXON("DSP", "DSP", operator, luxOnAdmin) {
        _mint(address(this), 5000000000 * 10 ** uint(decimals()));
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../LuxOn/SuperOperators.sol";

contract GovernorMemo is SuperOperators {

    event ExecuteMemo(string propose);

    function memo(string memory propose) external onlySuperOperator {
        emit ExecuteMemo(propose);
    }
}
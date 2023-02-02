// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../../Admin/LuxOnService.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LuxOnLive is Ownable {
    address private luxOnService;

    event SetLuxOnService(address indexed luxOnService);

    constructor(
        address _luxOnService
    ) {
        luxOnService = _luxOnService;
    }

    function getLuxOnService() public view returns (address) {
        return luxOnService;
    }

    function setLuxOnService(address _luxOnService) external onlyOwner {
        luxOnService = _luxOnService;
        emit SetLuxOnService(_luxOnService);
    }

    modifier isLive() {
        require(LuxOnService(luxOnService).isLive(address(this)), "LuxOnLive: not live");
        _;
    }
}
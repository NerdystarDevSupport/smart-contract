// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../../../utils/SuperOperators.sol";

contract MemorialCrystal is ERC1155, SuperOperators, Pausable, ERC1155Burnable, ERC1155Supply {
    string private _name;
    string private _symbol;

    uint8 private startSeasonId = 1;
    uint16 public lastSeasonId = 5;

    constructor() ERC1155(
        "https://gateway.pinata.cloud/ipfs/QmSWAW9DQwoiceP4WH8rXAkjBwLFmLAwxwSrYs9QUKkz39"
    ) {
        _name = "Desperado: Crystal";
        _symbol = "Chronicle";
    }

    function getLastSeason() public view onlyOwner returns (uint16) {
        return lastSeasonId;
    }

    function addNewSeason() external onlyOwner {
        lastSeasonId = lastSeasonId + 1;
    }

    function setName(string memory name_) external onlyOwner {
        _name = name_;
    }

    function setSymbol(string memory symbol_) external onlyOwner {
        _symbol = symbol_;
    }

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
    public
    onlySuperOperator
    {
        _mint(account, id, amount, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public whenNotPaused override {
        require(
            from == _msgSender() || _superOperators[msg.sender] || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    public
    onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    whenNotPaused
    override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function uri(uint256 _tokenId) override public view returns (string memory) {
        return string(
            abi.encodePacked(
                super.uri(0), "/", Strings.toString(_tokenId), ".json"
            )
        );
    }

    function airdropSingle(address[] memory receivers, uint256[] memory ids, uint256[] memory amount, bytes memory data)
    public
    onlyOwner
    {
        uint batchSize = receivers.length;
        for (uint256 i; i < batchSize; ++i) {
            _mint(receivers[i], ids[i], amount[i], data);
        }
    }

    function airdrop(address[] memory receivers, uint256[][] memory ids, uint256[][] memory amount, bytes memory data)
    public
    onlyOwner
    {
        uint batchSize = receivers.length;
        require(
            batchSize == ids.length &&
            batchSize == amount.length,
            "Size not matched"
        );

        for (uint256 i; i < batchSize; ++i) {
            _mintBatch(receivers[i], ids[i], amount[i], data);
        }
    }
}
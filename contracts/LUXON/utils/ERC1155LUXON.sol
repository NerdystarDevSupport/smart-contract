// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./LuxOnSuperOperators.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ERC1155LUXON is ERC1155, ERC1155Supply, LuxOnSuperOperators {
    string private _name;
    string private _symbol;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_,
        string memory operator,
        address luxOnAdmin
    ) ERC1155(uri_) LuxOnSuperOperators(operator, luxOnAdmin) {
        _name = name_;
        _symbol = symbol_;
    }

    function setName(string memory name_) external virtual onlyOwner {
        _name = name_;
    }

    function setSymbol(string memory symbol_) external virtual onlyOwner {
        _symbol = symbol_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function setURI(string memory newuri) external virtual onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) external virtual onlySuperOperator {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external virtual onlySuperOperator {
        _mintBatch(to, ids, amounts, data);
    }

    function burn(address account, uint256 id, uint256 value) external virtual onlySuperOperator {
        _burn(account, id, value);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external virtual onlySuperOperator {
        _burnBatch(account, ids, values);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override (ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public virtual override {
        require(
            from == _msgSender() || isSuperOperator(msg.sender) || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    function uri(uint256 _tokenId) override public view returns (string memory) {
        return string(
            abi.encodePacked(
                super.uri(0), "/", Strings.toString(_tokenId)
            )
        );
    }
}
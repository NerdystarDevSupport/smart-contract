// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "/contracts/LUXON/utils/LuxOnSuperOperators.sol";
import "/contracts/LUXON/utils/IERC20LUXON.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract DesperadoMarketList is LuxOnSuperOperators {
    enum CenteralizationType { Centralization, Decentralization }
    enum TokenType { ERC20, ERC721, ERC1155 }
    enum SalesGoods { Matic, LXN, BT }

    event Registe(uint256 indexed _marketplaceId, address indexed _registrant, Product product);
    event Sell(uint256 indexed _marketplaceId, address indexed _seller, Product product);
    event Cancel(uint256 indexed _marketplaceId, Product product);

    struct Product {
        uint256 id;
        address registrant;
        address product;
        uint256 productId;
        uint256 amount;
        uint256 price;
        CenteralizationType centeralizationType;
        TokenType tokenType;
        SalesGoods salesGoods;
        bool isValid;
    }

    constructor(
        string memory operator,
        address luxOnAdmin
    ) LuxOnSuperOperators(operator, luxOnAdmin) {}

    mapping(uint256 => Product) private productList;

    uint256 private marketplaceId = 0;

    function isOpenMarketplace(uint256 _marketplaceId) public view returns (bool) {
        return (productList[_marketplaceId].registrant != address(0) && productList[_marketplaceId].closeTime >= block.timestamp);
    }

    function getMarketplaceInfo(uint256 _marketplaceId) public view returns (Product memory) {
        return productList[_marketplaceId];
    }

    function getMarketplaceInfoPage(uint256 limit, uint256 offset) public view returns (Product[] memory) {
        Product[] memory productes = new Product[](limit);
        for (uint256 i = 0; i < limit; i++) {
            productes[i] = productList[offset + i];
        }
        return productes;
    }

    function registeProductList(address _registrant, address _product, uint256 _tokenId, uint256 _amount, address _salesGoods, uint256 _price, uint256 addCloseTime, TokenType _tokenType) external onlySuperOperator {
        Product memory product = Product(marketplaceId, _registrant, _product, _tokenId, _amount, _salesGoods, _price * 10 ** uint(IERC20LUXON(_salesGoods).decimals()), block.timestamp + addCloseTime, _tokenType);
        productList[marketplaceId] = product;
        emit Registe(marketplaceId++, _registrant, product);
    }

    function sellProductList(uint256 _marketplaceId, address _seller) external onlySuperOperator {
        emit Sell(_marketplaceId, _seller, productList[_marketplaceId]);
        delete productList[_marketplaceId];
    }

    function cancelProductList(uint256 _marketplaceId) external onlySuperOperator {
        emit Cancel(_marketplaceId, productList[_marketplaceId]);
        delete productList[_marketplaceId];
    }
}

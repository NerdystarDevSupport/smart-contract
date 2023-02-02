// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "/contracts/LUXON/utils/Payback.sol";
import "/contracts/LUXON/utils/SuperOperators.sol";
import "/contracts/LUXON/utils/IERC20LUXON.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "/contracts/LUXON/marketplace/desperado/DesperadoMarketList.sol";
import "/contracts/LUXON/utils/Staking.sol";
import "/contracts/LUXON/utils/ERC721LUXON.sol";
import "/contracts/LUXON/myPage/centraliztion/ERC721Centraliztion.sol";
import "/contracts/LUXON/myPage/centraliztion/ERC1155Centraliztion.sol";

contract DesperadoMarketplace is Payback, SuperOperators, ReentrancyGuard, Staking, DesperadoMarketList {
    address private erc721CentraliztionAddress;
    address private erc1155CentraliztionAddress;
    address private desperadoMarketList;

    uint256 private feePercentageRate;
    uint256 private feePercentage;

    mapping(address => bool) salesGoodsList;

    constructor (
        address _erc721CentraliztionAddress,
        address _erc1155CentraliztionAddress,
        address paybackAddress,
        uint256 paybackPercentageRate,
        uint256 paybackPercentage,
        address _desperadoMarketList,
        uint256 _feePercentageRate,
        uint256 _feePercentage
    ) Payback(paybackAddress, paybackPercentageRate, paybackPercentage) {
        erc721CentraliztionAddress = _erc721CentraliztionAddress;
        erc1155CentraliztionAddress = _erc1155CentraliztionAddress;
        desperadoMarketList = _desperadoMarketList;
        feePercentageRate = _feePercentageRate;
        feePercentage = _feePercentage;
    }

    function setDesperadoMarketList(address _desperadoMarketList) external onlyOwner {
        desperadoMarketList = _desperadoMarketList;
    }

    function setSalesGoodsList(address salesGoodsAddress, bool isTrue) external onlyOwner {
        salesGoodsList[salesGoodsAddress] = isTrue;
    }

    function registerProduct(address _registrant, address _product, uint256 _tokenId, uint256 _amount, address _salesGoods, uint256 _price, uint256 addCloseTime) external onlySuperOperator {
        require (_amount <= ERC1155Centraliztion(erc1155CentraliztionAddress).getRealOwnerAmount(_product, _tokenId, _registrant), "The quantity is insufficient");
        require (salesGoodsList[_salesGoods], "Invalid goods.");
        require (_amount > 0, "Invalid amount");
        require (_price > 0, "Invalid price");
        DesperadoMarketList(desperadoMarketList).registeProductList(_registrant, _product, _tokenId, _amount, _salesGoods, _price, addCloseTime, TokenType.ERC1155);
    }

    function registerProduct(address _registrant, address _product, uint256 _tokenId, address _salesGoods, uint256 _price, uint256 addCloseTime) external onlySuperOperator {
        require (_registrant == ERC721Centraliztion(erc721CentraliztionAddress).getRealOwner(_product, _tokenId), "is not the owner");
        require (salesGoodsList[_salesGoods], "Invalid goods.");
        require (_price > 0, "Invalid price");
        DesperadoMarketList(desperadoMarketList).registeProductList(_registrant, _product, _tokenId, 1, _salesGoods, _price, addCloseTime, TokenType.ERC721);
    }

    function purchaseProduct(address purchaser, uint256 _marketplaceId) external onlySuperOperator {
        Product memory product = DesperadoMarketList(desperadoMarketList).getMarketplaceInfo(_marketplaceId);
        require (product.closeTime >= block.timestamp, "This is a closed store.");
        require (IERC20LUXON(product.salesGoods).balanceOf(purchaser) >= product.price, "The payment is insufficient.");

        divisionPrice(purchaser, product);
        paybackByMint(purchaser, product.price);

        if (TokenType.ERC721 == product.tokenType) {
            require (product.registrant == ERC721Centraliztion(erc721CentraliztionAddress).getRealOwner(product.product, product.tokenId), "is not the owner");
            ERC721Centraliztion(erc721CentraliztionAddress).transferCenter(product.registrant, product.product, product.tokenId, purchaser);
        } else if (TokenType.ERC1155 == product.tokenType) {
            require (product.amount <= ERC1155Centraliztion(erc1155CentraliztionAddress).getRealOwnerAmount(product.product, product.tokenId, product.registrant), "The quantity is insufficient");
            ERC1155Centraliztion(erc1155CentraliztionAddress).transferCenter(product.registrant, product.product, product.tokenId, purchaser, product.amount);
        }

        DesperadoMarketList(desperadoMarketList).sellProductList(_marketplaceId, purchaser);
    }

    function cancelProduct(address _registrant, uint256 _marketplaceId) external onlySuperOperator {
        Product memory product = DesperadoMarketList(desperadoMarketList).getMarketplaceInfo(_marketplaceId);
        require (product.closeTime >= block.timestamp, "This is already closed store.");
        require (product.registrant == _registrant, "This product is not yours");

        DesperadoMarketList(desperadoMarketList).cancelProductList(_marketplaceId);
    }


    function divisionPrice(address purchaser, Product memory _product) private {
        uint256 fee = _product.price / feePercentageRate * feePercentage;
        (address tokenAddress, address contractAddress, uint256 percentageRate, uint256 percentage) = getStakingContractInfo(_product.product);
        require (tokenAddress == _product.product, "not valid product address");
        uint256 stakeAmount = fee / percentageRate * percentage;
        uint256 feeAmount = fee - stakeAmount;
        uint256 sellAmount = _product.price - fee;

        IERC20LUXON(_product.salesGoods).transferFrom(purchaser, address(this), feeAmount);
        IERC20LUXON(_product.salesGoods).transferFrom(purchaser, contractAddress, stakeAmount);
        IERC20LUXON(_product.salesGoods).transferFrom(purchaser, _product.registrant, sellAmount);
    }

    function withdrawMoney(address withdrawAddress) external onlyOwner nonReentrant {
        (bool success) = IERC20LUXON(withdrawAddress).transferFrom(address(this), msg.sender, IERC20LUXON(withdrawAddress).balanceOf(address(this)));
        require(success, "Transfer failed.");
    }
}
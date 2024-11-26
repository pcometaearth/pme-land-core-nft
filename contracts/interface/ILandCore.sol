// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILandCore {
    struct Land {
        uint256 id;
        address owner;
        uint256 tileCount;
        uint64 purchaseTimestamp;
        uint256 purchasePriceUSD;
        uint256 purchasePriceToken;
        string tokenType;
        string tileData;
        bool isForSale;
    }

    function getAllTileData() external view returns (string[] memory);

    function getLandsByOwner(
        address owner
    ) external view returns (Land[] memory);

    function lands(
        uint256 landId
    )
        external
        view
        returns (
            uint256 id,
            address owner,
            uint256 tileCount,
            uint64 purchaseTimestamp,
            uint256 purchasePriceUSD,
            uint256 purchasePriceToken,
            string memory tokenType,
            string memory tileData,
            bool isForSale
        );

    function nextLandId() external view returns (uint256);

    function pmbToken() external view returns (IERC20);

    function pmgToken() external view returns (IERC20);

    function pmeToken() external view returns (IERC20);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PriceConsumerV3 is Ownable(msg.sender) {
    AggregatorV3Interface internal _priceFeed;

    function setPriceFeed(address priceFeed_) external onlyOwner {
        _priceFeed = AggregatorV3Interface(priceFeed_);
    }

    function getUSDToTokenAmount(
        uint256 usdAmount_,
        uint8 usdDecimals_
    ) external view returns (uint256) {
        (, int _price, , , ) = _priceFeed.latestRoundData();
        if (_price > 0) {
            uint256 _tokenDecimals = 10 ** _priceFeed.decimals();
            uint256 _usdDecimals = 10 ** usdDecimals_;

            uint256 _tokenAmount = ((((usdAmount_ * _tokenDecimals) /
                uint(_usdDecimals)) * _tokenDecimals) / uint(_price));

            return _tokenAmount;
        }
        revert("Price is not set");
    }
}

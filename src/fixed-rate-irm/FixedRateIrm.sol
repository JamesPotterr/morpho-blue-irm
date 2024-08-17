// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IIrm} from "../../lib/morpho-blue/src/interfaces/IIrm.sol";
import {IFixedRateIrm} from "./interfaces/IFixedRateIrm.sol";

import {MarketParamsLib} from "../../lib/morpho-blue/src/libraries/MarketParamsLib.sol";
import {Id, MarketParams, Market} from "../../lib/morpho-blue/src/interfaces/IMorpho.sol";

/* ERRORS */

/// @dev Thrown when the rate is not already set for this market.
error RateNotSet();
/// @dev Thrown when the rate is already set for this market.
error RateAlreadySet();
/// @dev Thrown when trying to set the rate to zero.
error RateZero();
/// @dev Thrown when trying to set a rate that is too high.
error RateTooHigh();

/* CONSTANTS */

/// @title FixedRateIrm
/// @notice Contract that implements a fixed rate interest rate model.
contract FixedRateIrm is IFixedRateIrm {
    using MarketParamsLib for MarketParams;

    /// @inheritdoc IFixedRateIrm
    uint256 public constant MAX_BORROW_RATE = 8e18 / uint256(365 days);

    /* STORAGE */

    /// @inheritdoc IFixedRateIrm
    mapping(Id => uint256) public borrowRateStored;

    /* EVENTS */

    /// @inheritdoc IFixedRateIrm
    event SetBorrowRate(Id indexed id, uint256 newBorrowRate);

    /* SETTER */

    /// @inheritdoc IFixedRateIrm
    function setBorrowRate(Id id, uint256 newBorrowRate) external {
        if (borrowRateStored[id] != 0) revert RateAlreadySet();
        if (newBorrowRate == 0) revert RateZero();
        if (newBorrowRate > MAX_BORROW_RATE) revert RateTooHigh();

        borrowRateStored[id] = newBorrowRate;

        emit SetBorrowRate(id, newBorrowRate);
    }

    /* BORROW RATES */

    /// @inheritdoc IIrm
    function borrowRateView(MarketParams memory marketParams, Market memory) external view returns (uint256) {
        uint256 borrowRateCached = borrowRateStored[marketParams.id()];
        if (borrowRateCached == 0) revert RateNotSet();
        return borrowRateCached;
    }

    /// @inheritdoc IIrm
    /// @dev Reverts if the rate is not set, so the rate must be set before the market creation.
    function borrowRate(MarketParams memory marketParams, Market memory) external view returns (uint256) {
        uint256 borrowRateCached = borrowRateStored[marketParams.id()];
        if (borrowRateCached == 0) revert RateNotSet();
        return borrowRateCached;
    }
}

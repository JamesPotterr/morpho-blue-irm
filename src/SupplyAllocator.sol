// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {IPool} from "src/interfaces/IPool.sol";
import {ISupplyAllocator} from "src/interfaces/ISupplyAllocator.sol";

import {Math} from "@morpho-utils/math/Math.sol";
import {PoolLib} from "src/libraries/PoolLib.sol";
import {PoolAddress} from "src/libraries/PoolAddress.sol";
import {BytesLib, POOL_OFFSET} from "src/libraries/BytesLib.sol";

contract SupplyAllocator is ISupplyAllocator {
    using PoolLib for IPool;
    using BytesLib for bytes;

    address internal immutable FACTORY;

    constructor(address factory) {
        FACTORY = factory;
    }

    function getPool(
        address collateral,
        address asset
    ) internal view returns (IPool) {
        return IPool(PoolAddress.computeAddress(FACTORY, collateral, asset));
    }

    function allocateSupply(
        address asset,
        uint256 amount,
        bytes memory collateralization
    ) external view returns (bytes memory allocation) {
        uint256 highestApr;
        bytes memory highestCollateralLtv;

        uint256 length = collateralization.length;
        for (uint256 start; start < length; start += POOL_OFFSET) {
            (address collateral, uint16 maxLtv) = collateralization
                .decodeCollateralLtv(start);

            IPool pool = getPool(collateral, asset);
            uint256 hypotheticalApr = pool.apr(maxLtv, amount);

            if (highestApr < hypotheticalApr) {
                highestApr = hypotheticalApr;
                highestCollateralLtv = abi.encodePacked(asset, maxLtv);
            }
        }

        allocation = abi.encodePacked(highestCollateralLtv, amount);
    }

    function allocateWithdraw(
        address asset,
        uint256 amount,
        bytes memory collateralization
    ) external view returns (bytes memory allocation) {
        uint256 lowestApr;
        bytes memory lowestCollateralLtv;

        IPool pool;
        uint256 start;

        uint256 length = collateralization.length;
        for (; start < length; start += POOL_OFFSET) {
            (address collateral, uint16 maxLtv) = collateralization
                .decodeCollateralLtv(start);

            pool = getPool(collateral, asset);
            uint256 hypotheticalApr = pool.apr(maxLtv, 0);

            if (lowestApr > hypotheticalApr) {
                lowestApr = hypotheticalApr;
                lowestCollateralLtv = abi.encodePacked(asset, maxLtv);
            }
        }

        // Also check for available liquidity to guarantee optimal liquidity (at the cost of sub-optimal APR):

        (address lowestCollateral, uint16 lowestMaxLtv) = lowestCollateralLtv
            .decodeCollateralLtv(0);

        pool = getPool(lowestCollateral, asset);
        uint256 withdrawn = Math.min(amount, pool.liquidity(lowestMaxLtv));

        allocation = abi.encodePacked(lowestCollateralLtv, withdrawn);
        amount -= withdrawn;

        for (start = 0; start < length; start += POOL_OFFSET) {
            if (amount == 0) break;

            (address collateral, uint16 maxLtv) = collateralization
                .decodeCollateralLtv(start);

            if (collateral == lowestCollateral) continue;

            pool = getPool(collateral, asset);
            withdrawn = Math.min(amount, pool.liquidity(maxLtv));

            allocation = abi.encodePacked(
                allocation,
                collateral,
                maxLtv,
                withdrawn
            );
            amount -= withdrawn;
        }
    }
}

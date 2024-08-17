// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IIrm} from "../../../lib/morpho-blue/src/interfaces/IIrm.sol";
import {Id} from "../../../lib/morpho-blue/src/interfaces/IMorpho.sol";

/// @title IAdaptiveCurveIrm
/// @author Morpho Labs
/// @custom:contact security@morpho.org
/// @notice Interface exposed by the AdaptiveCurveIrm.
interface IAdaptiveCurveIrm is IIrm {
    /// @notice Returns the address of the Morpho contract.
    function MORPHO() external view returns (address);

    /// @notice Returns the rate at target utilization for a given market.
    /// @dev Tells the height of the curve. The 'Id' type is used to reference a specific market.
    /// @param id The identifier of the market.
    /// @return rate The rate at the target utilization.
    function rateAtTarget(Id id) external view returns (int256 rate);
}

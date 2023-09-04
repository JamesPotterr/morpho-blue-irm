// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {WAD, MathLib as MorphoMathLib} from "morpho-blue/libraries/MathLib.sol";
import {ErrorsLib} from "./ErrorsLib.sol";

int256 constant WAD_INT = int256(WAD);

library MathLib {
    using MathLib for uint128;
    using MathLib for uint256;
    using {wDivDown} for int256;
    using {wMulDown} for int256;

    /// @dev ln(2).
    int256 private constant LN2_INT = 0.693147180559945309 ether;

    /// @dev Returns an approximation of exp.
    function wExp(int256 x) internal pure returns (uint256) {
        unchecked {
            // Revert if x > ln(2^256-1) ~ 177.
            require(x <= 177.44567822334599921 ether, ErrorsLib.WEXP_OVERFLOW);

            // Decompose x as x = q * ln(2) + r with q an integer and -ln(2)/2 < r <= ln(2)/2.
            int256 q = (x + (LN2_INT / 2)) / LN2_INT;
            // Safe unchecked because |q * LN2_INT| <= x.
            int256 r = x - q * LN2_INT;

            // Compute e^r with a 2nd-order Taylor polynomial.
            // Safe unchecked because |r| < 1, expR < 2 and the sum is positive.
            uint256 expR = uint256(WAD_INT + r + r.wMulDown(r) / 2);

            // Return e^x = 2^q * e^r.
            if (q >= 0) return expR << uint256(q);
            else return expR >> uint256(-q);
        }
    }

    function wMulDown(int256 a, int256 b) internal pure returns (int256) {
        return a * b / WAD_INT;
    }

    function wDivDown(int256 a, int256 b) internal pure returns (int256) {
        return a * WAD_INT / b;
    }
}

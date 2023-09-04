// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "solmate/utils/SignedWadMath.sol";
import "../../src/irm/libraries/MathLib.sol";
import "../../src/irm/libraries/ErrorsLib.sol";

contract MathLibTest is Test {
    using MathLib for uint128;
    using MathLib for uint256;

    function testWExp(int256 x) public {
        vm.assume(x > -176 ether);
        vm.assume(x < 135305999368893231589);
        assertApproxEqRel(int256(MathLib.wExp(x)), wadExp(x), 0.05 ether);
    }

    function testWExpSmall(int256 x) public {
        vm.assume(x <= -178 ether);
        assertEq(MathLib.wExp(x), 0);
    }

    function testWExpRevertTooLarge(int256 x) public {
        vm.assume(x >= 178 ether);
        vm.expectRevert(bytes(ErrorsLib.WEXP_OVERFLOW));
        MathLib.wExp(x);
    }
}

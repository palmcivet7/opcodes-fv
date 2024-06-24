// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.3;

import {Base_Test, console2} from "./Base_Test.t.sol";
import {MathMasters} from "src/MathMasters.sol";
import {Harness} from "../certora/harness/Harness.sol";

contract MathMastersTest is Base_Test {
    function testMulWad() public {
        assertEq(MathMasters.mulWad(2.5e18, 0.5e18), 1.25e18);
        assertEq(MathMasters.mulWad(3e18, 1e18), 3e18);
        assertEq(MathMasters.mulWad(369, 271), 0);
    }

    function testMulRevert() public {
        MathMasters.mulWad(type(uint256).max, type(uint256).max);
    }

    function testMulWadFuzz(uint256 x, uint256 y) public pure {
        // Ignore cases where x * y overflows.
        unchecked {
            if (x != 0 && (x * y) / x != y) return;
        }
        assert(MathMasters.mulWad(x, y) == (x * y) / 1e18);
    }

    function testMulWadUp() public {
        assertEq(MathMasters.mulWadUp(2.5e18, 0.5e18), 1.25e18);
        assertEq(MathMasters.mulWadUp(3e18, 1e18), 3e18);
        assertEq(MathMasters.mulWadUp(369, 271), 1);
    }

    function testMulWadUpUnit() public {
        uint256 x = 53438770891273403451;
        uint256 y = 53438770891273403445;
        uint256 result = MathMasters.mulWadUp(x, y);
        uint256 expected = x * y == 0 ? 0 : (x * y - 1) / 1e18 + 1;
        uint256 resultDown = MathMasters.mulWad(x, y);
        console2.log("result:", result); // 2855702234370009622372
        console2.log("expected:", expected); // 2855702234370009622319
        console2.log("resultDown:", resultDown); // 2855702234370009622318
        assert(result != expected);
        assertEq(resultDown, expected - 1);
    }

    function testMulWadUpFuzz(uint256 x, uint256 y) public {
        // We want to skip the case where x * y would overflow.
        // Since Solidity 0.8.0 checks for overflows by default,
        // we cannot just multiply x and y as this could revert.
        // Instead, we can ensure x or y is 0, or
        // that y is less than or equal to the maximum uint256 value divided by x
        if (x == 0 || y == 0 || y <= type(uint256).max / x) {
            uint256 result = MathMasters.mulWadUp(x, y);
            uint256 expected = x * y == 0 ? 0 : (x * y - 1) / 1e18 + 1;
            console2.log("result:", result);
            console2.log("expected:", expected);
            assertEq(result, expected);
        }
        // If the conditions for x and y are such that x * y would overflow,
        // this function will simply not perform the assertion.
        // In a testing context, you might want to handle this case differently,
        // depending on whether you want to consider such an overflow case as passing or failing.
    }

    // halmos --function check_testMulWadUpFuzz --solver-timeout-assertion 0
    // x = 392963816396865184060895128519472638745
    // y = 289133969112664987748073243965073899540
    function check_testMulWadUpFuzz(uint256 x, uint256 y) public pure {
        if (x == 0 || y == 0 || y <= type(uint256).max / x) {
            uint256 result = MathMasters.mulWadUp(x, y);
            uint256 expected = x * y == 0 ? 0 : (x * y - 1) / 1e18 + 1;
            assert(result == expected);
        }
    }

    function testMulWadupUnitHalmos() public pure {
        uint256 x = 392963816396865184060895128519472638745;
        uint256 y = 289133969112664987748073243965073899540;
        uint256 result = MathMasters.mulWadUp(x, y);
        uint256 resultDown = MathMasters.mulWad(x, y);
        console2.log("result:", result);
        console2.log("resultDown:", resultDown);
        assert(result != resultDown);
    }

    function testMulWadupUnitCertora() public pure {
        uint256 x = 0xde0b6b3a7640001;
        uint256 y = 0xde0b6b3a7640000;
        uint256 result = MathMasters.mulWadUp(x, y);
        uint256 resultDown = MathMasters.mulWad(x, y);
        console2.log("result:", result);
        console2.log("resultDown:", resultDown);
        assert(result != resultDown);
    }

    function testSqrt() public {
        assertEq(MathMasters.sqrt(0), 0);
        assertEq(MathMasters.sqrt(1), 1);
        assertEq(MathMasters.sqrt(2704), 52);
        assertEq(MathMasters.sqrt(110889), 333);
        assertEq(MathMasters.sqrt(32239684), 5678);
        assertEq(MathMasters.sqrt(type(uint256).max), 340282366920938463463374607431768211455);
    }

    function testSqrtFuzzUni(uint256 x) public pure {
        assert(MathMasters.sqrt(x) == uniSqrt(x));
    }

    function testSqrtFuzzSolmate(uint256 x) public pure {
        assert(MathMasters.sqrt(x) == solmateSqrt(x));
    }

    function testSqrtWithCertoraEdgeCase() public pure {
        uint256 x = 0xffff2bffffffffffffffffffffffffffffffffffffffff;
        assert(MathMasters.sqrt(x) == solmateSqrt(x));
    }

    function testHarnessFuzz(uint256 x) public {
        Harness harness = new Harness();
        assertEq(harness.mathMastersTopHalf(x), harness.solmateTopHalf(x));
    }

    function testHarnessWithCertoraEdgeCase() public {
        uint256 x = 0xffff2bffffffffffffffffffffffffffffffffffffffff;
        Harness harness = new Harness();
        assertEq(harness.mathMastersTopHalf(x), harness.solmateTopHalf(x));
    }

    function test_sqrt_breaks() public {
        // 24519788349697037967053404880661006174729938985413509120
        // 309481597173691432457732096
        // 72057151656296448
        // 105311287332279524828995813957362719092269727931050867564254068736
        // 5708982944329400342648484220182009614862188543
        // 1329211357870787877392912416050774016
        // 452312201544546376757969088181825051580699710308692317009311379840200343552
        uint256 x = 105311293498665291426722909308999732236070323463302251608708546560;

        Harness harness = new Harness();
        uint256 mathMastersOutput = harness.mathMastersTopHalf(x);
        uint256 solmateOutput = harness.solmateTopHalf(x);
        console2.log("mathMastersOutput:", mathMastersOutput);
        console2.log("solmateOutput    :", solmateOutput);

        assert(mathMastersOutput != solmateOutput);
    }

    function check_testHarnessWithCertoraEdgeCase(uint256 x) public {
        Harness harness = new Harness();
        assert(harness.mathMastersTopHalf(x) == harness.solmateTopHalf(x));
    }

    /// challenge

    // halmos --function check_challenge --solver-timeout-assertion 0
    // x = 392963816396865184060895128519472638745
    // y = 289133969112664987748073243965073899540
    function check_challenge(uint256 x) public {
        Harness harness = new Harness();
        assert(harness.challengeExp(x) == harness.helperExp(x));
    }

    function test_challenge() public {
        uint256 x = 0x00000000000000000000000000000000000000000000003dffffffffffffff80;
        Harness harness = new Harness();
        assert(harness.challengeExp(x) == harness.helperExp(x));
    }
}

/*
    Verification of Sqrt for MathMasters
*/

methods {
    // function mathMastersSqrt(uint256) external returns (uint256) envfree;
    // function uniSqrt(uint256) external returns (uint256) envfree;
    function mathMastersTopHalf(uint256) external returns (uint256) envfree;
    function solmateTopHalf(uint256) external returns (uint256) envfree;
}

// rule uniSqrtMatchesMathMastersSqrt(uint256 x)  {
//     assert(mathMastersSqrt(x) == uniSqrt(x));
// }

rule solmateTopHalfMatchesMathMastersTopHalf(uint256 x) {
    // require(x != 0xffff2bffffffffffffffffffffffffffffffffffffffff);
    assert(mathMastersTopHalf(x) == solmateTopHalf(x));
}
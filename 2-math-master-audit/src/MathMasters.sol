// SPDX-License-Identifier: MIT
// @notice We intentionally want to leave this as floating point so others can use it as a library.
// @audit-info solc version
pragma solidity ^0.8.3;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @notice People taking my course: Don't cheat and look at the answers!
/// @author Math Masters
/// @author Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library MathMasters {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error MathMasters__FactorialOverflow();
    error MathMasters__MulWadFailed();
    error MathMasters__DivWadFailed();
    error MathMasters__FullMulDivFailed();

    /*//////////////////////////////////////////////////////////////
    /*                         CONSTANTS                          */
    //////////////////////////////////////////////////////////////*/
    /// @dev The scalar of ETH and most ERC20s.
    uint256 internal constant WAD = 1e18; // WAD just means 18 decimal places

    // History lesson: WAD, RAY, and RAD were introduced in DappHub/DappTools/the DS test system and popularized by MakerDAO's original DAI system. The names sort of stuck.
    // https://github.com/dapphub
    // wad: fixed point decimal with 18 decimals (for basic quantities, e.g. balances)
    // ray: fixed point decimal with 27 decimals (for precise quantites, e.g. ratios)
    // rad: fixed point decimal with 45 decimals (result of integer multiplication with a wad and a ray)

    /*//////////////////////////////////////////////////////////////
    /*              SIMPLIFIED FIXED POINT OPERATIONS             */
    //////////////////////////////////////////////////////////////*/

    /// @dev Equivalent to `(x * y) / WAD` rounded down.
    function mulWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(
                y,
                gt(
                    x,
                    div(not(0), y) // 0xFFFFFF.....
                )
            ) {
                // if big_num / y > x -> 0
                // if big_num / y < x -> 1
                // Memory [0x40: 0xbac65e5b]
                // @audit-low this will revert with a blank message
                // @audit - why are you overriding the free memory pointer?
                // @audit - wrong function selector - 0xa56044f7
                mstore(0x40, 0xbac65e5b) // `MathMasters__MulWadFailed()`.
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), WAD)
            // 100 / 109
            // 0.8787 -> 0
            // rounds down to 0
        }
    }

    /// @dev Equivalent to `(x * y) / WAD` rounded up.
    // 3 / 5 -> 1
    // 0.6 should round up to 1
    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(
                y,
                gt(
                    x,
                    div(not(0), y) // 0xFFFFFF.... / y
                )
            ) {
                // @audit this is wrong for a bunch of reasons
                mstore(0x40, 0xbac65e5b) // `MathMasters__MulWadFailed()`.
                revert(0x1c, 0x04)
            }
            // e adding 1 to x if (0 + x/y) - 1 == 0
            // @audit-high, this line is wrong and not needed
            if iszero(
                sub(
                    div(add(z, x), y), // is this zero? ((0 + x / y) - 1)
                    1
                )
            ) { x := add(x, 1) }

            z :=
                add(
                    iszero(
                        iszero(
                            mod(mul(x, y), WAD) // x * y % 1e18 -> remainder
                        )
                    ), // checking if it divides evenly
                    div(mul(x, y), WAD)
                )
        }
    }

    /*//////////////////////////////////////////////////////////////
    /*                  GENERAL NUMBER UTILITIES                  */
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the square root of `x`.
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := 181

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.
            // 87112285931760246646623899502532662132735: 0xffffffffffffffffffffffffffffffffff
            let r := shl(7, lt(0xffffffffffffffffffffffffffffffffff, x))
            // 4722366482869645213695: 0xffffffffffffffffff
            r := or(r, shl(6, lt(0xffffffffffffffffff, shr(r, x))))
            // 1099511627775: 0xffffffffff
            r := or(r, shl(5, lt(0xffffffffff, shr(r, x))))
            // Correct: 16777215 0xffffff
            // 16777002: 0xffff2a
            r := or(r, shl(4, lt(0xffff2a, shr(r, x))))
            z := shl(shr(1, r), z)

            // There is no overflow risk here since `y < 2**136` after the first branch above.
            z := shr(18, mul(z, add(shr(r, x), 65536))) // A `mul()` is saved from starting `z` at 181.
            // @audit-high everything above this can be proven to be different to solmate sqrt

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If `x+1` is a perfect square, the Babylonian method cycles between
            // `floor(sqrt(x))` and `ceil(sqrt(x))`. This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            z := sub(z, lt(div(x, z), z))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {BaseTest_V1, IHorseStore} from "./BaseTest_V1.t.sol";
import {HorseStoreYul} from "../../src/horseStoreV1/HorseStoreYul.sol";

contract HorseStoreYulTest is BaseTest_V1 {
    function setUp() public override {
        horseStore = IHorseStore(address(new HorseStoreYul()));
    }
}

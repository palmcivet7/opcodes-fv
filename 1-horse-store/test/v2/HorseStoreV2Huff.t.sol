// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {BaseTest_V2, HorseStore} from "./BaseTest_V2.t.sol";
import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";

contract HorseStoreV2Huff is BaseTest_V2 {
    string public constant horseStoreLocation = "horseStoreV2/HorseStore";

    function setUp() public override {
        horseStore = HorseStore(
            HuffDeployer.config().with_args(bytes.concat(abi.encode(NFT_NAME), abi.encode(NFT_SYMBOL))).deploy(
                horseStoreLocation
            )
        );
    }
}

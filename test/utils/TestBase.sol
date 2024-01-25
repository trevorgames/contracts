// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { TestUtilities } from "./TestUtilities.sol";
import { TestLogging } from "./TestLogging.sol";

abstract contract TestBase is StdCheats, PRBTest, TestUtilities, TestLogging {
    address internal deployer = address(this);

    constructor() {
        vm.label(deployer, "Deployer");
    }
}

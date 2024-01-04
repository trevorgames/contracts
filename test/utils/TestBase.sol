// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { TestUtilities } from "./TestUtilities.sol";

abstract contract TestBase is StdCheats, PRBTest, TestUtilities {
    address internal deployer = address(this);

    constructor() {
        vm.label(deployer, "Deployer");
    }
}

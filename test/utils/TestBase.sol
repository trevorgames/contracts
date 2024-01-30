// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { TestUtilities } from "./TestUtilities.sol";
import { TestLogging } from "./TestLogging.sol";
import { TestErrors } from "./TestErrors.sol";
import { TestMeta } from "./TestMeta.sol";

abstract contract TestBase is StdCheats, PRBTest, TestUtilities, TestErrors, TestLogging, TestMeta {
    address internal leet = address(0x1337);
    address internal alice = address(0xa11ce);
    address internal deployer = address(this);

    bytes32 internal constant org1 = keccak256("1");
    bytes32 internal constant org2 = keccak256("2");
    uint32 internal constant guild1 = 1;
    uint32 internal constant guild2 = 2;

    constructor() {
        vm.label(deployer, "Deployer");
    }
}

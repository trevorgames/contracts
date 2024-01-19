// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { PRBTest } from "@prb/test/src/PRBTest.sol";

abstract contract TestUtilities is PRBTest {
    function signHashEthVRS(
        uint256 _privateKey,
        bytes32 _digest
    )
        internal
        pure
        returns (uint8 _v, bytes32 _r, bytes32 _s)
    {
        (_v, _r, _s) = vm.sign(_privateKey, toEthSignedMessageHash(_digest));
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

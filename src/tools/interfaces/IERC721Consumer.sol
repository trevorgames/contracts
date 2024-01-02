// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IERC721Consumer {
    function mintFromWorld(address, uint256) external;
    function isAdmin(address) external view returns (bool);
}

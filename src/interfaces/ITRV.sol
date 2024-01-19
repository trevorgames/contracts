// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITRV is IERC20 {
    function mint(address account, uint256 amount) external;
}

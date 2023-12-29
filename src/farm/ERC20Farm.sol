// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ITRV.sol";

contract ERC20Farm {
    using SafeERC20 for IERC20;

    address private immutable TRV;
    address private immutable ERC20_CONTRACT;
    uint256 public immutable EXPIRATION;
    uint256 private immutable RATE;

    mapping(address => uint256) public depositBalances;
    mapping(address => uint256) public depositBlocks;

    constructor(address trv, address erc20, uint256 rate, uint256 expiration) {
        TRV = trv;
        ERC20_CONTRACT = erc20;
        RATE = rate;
        EXPIRATION = block.number + expiration;
    }

    function calculateRewards(address account) public view returns (uint256 reward) {
        reward = (RATE * depositBalances[account] * (Math.min(block.number, EXPIRATION) - depositBlocks[account]))
            / (1 ether);
    }

    function claimRewards() public {
        uint256 reward = calculateRewards(msg.sender);

        if (reward > 0) {
            ITRV(TRV).mint(msg.sender, reward);
        }

        depositBlocks[msg.sender] = Math.min(block.number, EXPIRATION);
    }

    function deposit(uint256 amount) external {
        // TODO
        require(
            IERC20(ERC20_CONTRACT).balanceOf(address(this)) + amount <= 50e6 ether, "ERC20Farm: deposit cap reached"
        );
        claimRewards();
        IERC20(ERC20_CONTRACT).safeTransferFrom(msg.sender, address(this), amount);
        depositBalances[msg.sender] += amount;
    }

    function withdraw(uint256 amount) external {
        require(depositBalances[msg.sender] >= amount, "ERC20Farm: insufficient balance");

        claimRewards();

        unchecked {
            depositBalances[msg.sender] -= amount;
        }

        IERC20(ERC20_CONTRACT).safeTransfer(msg.sender, amount);
    }
}

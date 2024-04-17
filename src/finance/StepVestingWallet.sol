// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VestingWallet} from "@openzeppelin/contracts/finance/VestingWallet.sol";

contract StepVestingWallet is VestingWallet {
    uint64 private immutable _step;

    constructor(address beneficiary, uint64 startTimestamp, uint64 durationSeconds, uint64 stepSeconds)
    payable VestingWallet(beneficiary, startTimestamp, durationSeconds) {
        require(stepSeconds !=0 , "step should be non-zero");
        _step = stepSeconds;
    }

    /**
     * @dev Getter for the step size.
     */
    function step() public view virtual returns (uint256) {
        return _step;
    }

    /**
     * @dev Calculate the last vesting time. It may equals to the current block time.
     */
    function lastVestingTime() public view virtual returns (uint256) {
        return _lastVestingTime(uint64(block.timestamp));
    }

    /**
     * @dev Calculate the next vesting time.
     */
    function nextVestingTime() public view virtual returns (uint256) {
        return _nextVestingTime(uint64(block.timestamp));
    }


    /**
     * @dev Calculate the latest last vesting time with respect to specified current time.
     * 0 means the first vesting is not arrvied yet.
     */
    function _lastVestingTime(uint64 timestamp) internal view virtual returns (uint256) {
        if (timestamp < start() + step()) {
            return 0;
        } else if (timestamp >= end()) {
            return end();
        } else {
            uint256 numStep = (timestamp - start()) / step();
            return start() + numStep * step();
        }
    }

    /**
     * @dev Calculate the next vesting time with respect to specified current time.
     * 0 means no more vesting is scheduled in the future.
     */
    function _nextVestingTime(uint64 timestamp) internal view virtual returns (uint256) {
        if (timestamp < start() + step()) {
            return start() + step();
        } else if (timestamp >= end()) {
            return 0;
        } else {
            uint256 numStep = (timestamp - start()) / step() + 1;
            uint256 nvt = start() + numStep * step();
            if (nvt >= end()) {
                return end();
            } else {
                return nvt;
            }
        }
    }

    /**
     * @dev Overrides the parent implementation.
     */
    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp) internal view virtual override returns (uint256) {
        uint256 lvt = _lastVestingTime(timestamp);
        if (lvt == 0) {
            return 0;
        } else {
            return (totalAllocation * (lvt - start())) / duration();
        }
    }

}
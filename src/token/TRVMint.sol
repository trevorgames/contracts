// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TRVMint is Initializable, ERC20Upgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event Mint(address minter, address account, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address defaultAdmin) public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
    }

    function mint(address account, uint256 amount) public onlyRole(MINTER_ROLE) nonReentrant {
        _mint(account, amount);

        emit Mint(msg.sender, account, amount);
    }
}

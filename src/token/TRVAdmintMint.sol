// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TRVAdminMint is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
    }

    function adminMint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function adminBurn(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }

    function adminTransfer(address holder, address receiver, uint256 amount) public onlyOwner {
        _transfer(holder, receiver, amount);
    }
}

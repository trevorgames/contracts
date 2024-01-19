// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ERC20Consumer is ERC20Upgradeable, OwnableUpgradeable {
    address public worldAddress;

    mapping(address => bool) public isAdmin;

    function initialize() public initializer {
        __ERC20_init("ERC20Consumer", "ERC20C");
        __Ownable_init(msg.sender);
    }

    function setAdmin(address _address, bool _isAdmin) public onlyOwner {
        isAdmin[_address] = _isAdmin;
    }

    function setWorldAddress(address _worldAddress) public onlyOwner {
        worldAddress = _worldAddress;
    }

    function mintFromWorld(address _user, uint256 _tokenId) public {
        require(msg.sender == worldAddress, "Sender not world");
        _mint(_user, _tokenId);
    }

    function mintArbitrary(address _user, uint256 _quantity) public {
        _mint(_user, _quantity);
    }
}

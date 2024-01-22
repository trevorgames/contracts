// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { ERC1155Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ERC1155Consumer is ERC1155Upgradeable, OwnableUpgradeable {
    address public worldAddress;

    mapping(address => bool) public isAdmin;

    function initialize() public initializer {
        __ERC1155_init("uri");
        __Ownable_init(msg.sender);
    }

    function setAdmin(address _address, bool _isAdmin) public onlyOwner {
        isAdmin[_address] = _isAdmin;
    }

    function setWorldAddress(address _worldAddress) public onlyOwner {
        worldAddress = _worldAddress;
    }

    function mintFromWorld(address _user, uint256 _tokenId, uint256 _quantity) public {
        require(msg.sender == worldAddress, "Sender not world");
        _mint(_user, _tokenId, _quantity, "");
    }

    function mintArbitrary(address _user, uint256 _tokenId, uint256 _quantity) public {
        _mint(_user, _tokenId, _quantity, "");
    }
}

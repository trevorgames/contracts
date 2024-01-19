// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { ERC721EnumerableUpgradeable } from
    "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ERC721Consumer is ERC721EnumerableUpgradeable, OwnableUpgradeable {
    uint256 internal counter;
    address public worldAddress;

    mapping(address => bool) public isAdmin;

    function initialize() public initializer {
        __ERC721_init("ERC721Consumer", "ERC721C");
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
        for (uint256 i = 0; i < _quantity; i++) {
            _mint(_user, counter + i);
        }
        counter += _quantity;
    }

    function walletOfOwner(address _user) public view returns (uint256[] memory) {
        uint256 _tokenCount = balanceOf(_user);
        uint256[] memory _tokens = new uint256[](_tokenCount);

        for (uint256 i = 0; i < _tokenCount; i++) {
            _tokens[i] = tokenOfOwnerByIndex(_user, i);
        }

        return _tokens;
    }
}

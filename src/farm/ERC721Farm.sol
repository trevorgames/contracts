// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../interfaces/ITRV.sol";

contract ERC721Farm is ERC721Holder {
    using EnumerableSet for EnumerableSet.UintSet;

    address private immutable TRV;
    address private immutable ERC721_CONTRACT;
    uint256 public immutable EXPIRATION;
    uint256 private immutable RATE;

    mapping(address => EnumerableSet.UintSet) private _deposits;
    mapping(address => mapping(uint256 => uint256)) public depositBlocks;

    constructor(address trv, address erc721, uint256 rate, uint256 expiration) {
        TRV = trv;
        ERC721_CONTRACT = erc721;
        RATE = rate;
        EXPIRATION = block.number + expiration;
    }

    function depositsOf(address account) external view returns (uint256[] memory) {
        EnumerableSet.UintSet storage depositSet = _deposits[account];
        uint256[] memory tokenIds = new uint256[](depositSet.length());

        for (uint256 i; i < depositSet.length(); i++) {
            tokenIds[i] = depositSet.at(i);
        }

        return tokenIds;
    }

    function calculateRewards(
        address account,
        uint256[] memory tokenIds
    )
        public
        view
        returns (uint256[] memory rewards)
    {
        rewards = new uint256[](tokenIds.length);

        uint256 last = type(uint256).max;

        for (uint256 i = tokenIds.length; i > 0; i--) {
            uint256 tokenId = tokenIds[i - 1];
            require(tokenId < last);
            last = tokenId;

            rewards[i - 1] = RATE * (_deposits[account].contains(tokenId) ? 1 : 0)
                * (Math.min(block.number, EXPIRATION) - depositBlocks[account][tokenId]);
        }
    }

    function claimRewards(uint256[] calldata tokenIds) public {
        uint256 reward;
        uint256 depositBlock = Math.min(block.number, EXPIRATION);

        uint256[] memory rewards = calculateRewards(msg.sender, tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            reward += rewards[i];
            depositBlocks[msg.sender][tokenIds[i]] = depositBlock;
        }

        if (reward > 0) {
            ITRV(TRV).mint(msg.sender, reward);
        }
    }

    function deposit(uint256[] calldata tokenIds) external {
        claimRewards(tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            IERC721(ERC721_CONTRACT).safeTransferFrom(msg.sender, address(this), tokenIds[i], "");

            _deposits[msg.sender].add(tokenIds[i]);
        }
    }

    function withdraw(uint256[] calldata tokenIds) external {
        claimRewards(tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            require(_deposits[msg.sender].contains(tokenIds[i]), "ERC721Farm: token not deposited");

            _deposits[msg.sender].remove(tokenIds[i]);

            IERC721(ERC721_CONTRACT).safeTransferFrom(address(this), msg.sender, tokenIds[i], "");
        }
    }
}

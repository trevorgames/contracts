// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../interfaces/ITRV.sol";

contract ERC1155Farm is ERC1155Holder {
    using EnumerableSet for EnumerableSet.UintSet;

    address private immutable TRV;
    address private immutable ERC1155_CONTRACT;
    uint256 public immutable EXPIRATION;
    uint256 private immutable RATE;

    mapping(address => EnumerableSet.UintSet) private _deposits;
    mapping(address => mapping(uint256 => uint256)) public depositBalances;
    mapping(address => mapping(uint256 => uint256)) public depositBlocks;

    constructor(address trv, address erc1155, uint256 rate, uint256 expiration) {
        TRV = trv;
        ERC1155_CONTRACT = erc1155;
        RATE = rate;
        EXPIRATION = block.number + expiration;
    }

    function depositsOf(address account) external view returns (uint256[] memory tokenIds, uint256[] memory amounts) {
        EnumerableSet.UintSet storage depositSet = _deposits[account];
        tokenIds = new uint256[](depositSet.length());
        amounts = new uint256[](depositSet.length());

        for (uint256 i; i < depositSet.length(); i++) {
            tokenIds[i] = depositSet.at(i);
            amounts[i] = depositBalances[account][tokenIds[i]];
        }
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

            rewards[i - 1] = RATE * depositBalances[account][tokenId]
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

    function deposit(uint256[] calldata tokenIds, uint256[] calldata amounts) external {
        require(tokenIds.length == amounts.length, "ERC1155Farm: array length mismatch");

        claimRewards(tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 amount = amounts[i];

            IERC1155(ERC1155_CONTRACT).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");

            _deposits[msg.sender].add(tokenId);
            depositBalances[msg.sender][tokenId] += amount;
        }
    }

    function withdraw(uint256[] calldata tokenIds, uint256[] calldata amounts) external {
        require(tokenIds.length == amounts.length, "ERC1155Farm: array length mismatch");

        claimRewards(tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 amount = amounts[0];

            require(depositBalances[msg.sender][tokenId] >= amount, "ERC1155Farm: insufficient balance");

            unchecked {
                depositBalances[msg.sender][tokenId] -= amount;
            }

            if (depositBalances[msg.sender][tokenId] == 0) {
                _deposits[msg.sender].remove(tokenId);
            }

            IERC1155(ERC1155_CONTRACT).safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
        }
    }
}

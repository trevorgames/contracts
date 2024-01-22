// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { IERC721Consumer } from "./interfaces/IERC721Consumer.sol";
import { ERC721TokenStorageData, StakingStorage } from "./libraries/StakingStorage.sol";

struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

struct WithdrawRequest {
    address tokenAddress;
    address reciever;
    uint256 tokenId;
    uint256 nonce;
    bool stored;
    Signature signature;
}

contract StakingERC721 is Initializable {
    event ERC721Deposited(address tokenAddress, address depositor, address reciever, uint256 tokenId);
    event ERC721Withdrawn(address tokenAddress, address reciever, uint256 tokenId);

    function initialize() external initializer { }

    function depositERC721(address _tokenAddress, address _reciever, uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            // Toink it.
            ERC721Upgradeable(_tokenAddress).transferFrom(msg.sender, address(this), _tokenIds[i]);

            // Store it
            StakingStorage.setERC721TokenStorageData(
                _tokenAddress, _tokenIds[i], ERC721TokenStorageData(_reciever, true)
            );

            emit ERC721Deposited(_tokenAddress, msg.sender, _reciever, _tokenIds[i]);
        }
    }

    function withdrawERC721(WithdrawRequest[] calldata _withdrawRequests) public {
        for (uint256 i = 0; i < _withdrawRequests.length; i++) {
            WithdrawRequest calldata _withdrawRequest = _withdrawRequests[i];
            address _tokenAddress = _withdrawRequest.tokenAddress;

            ERC721TokenStorageData memory _erc721TokenStorageData =
                StakingStorage.getERC721TokenStorageData(_tokenAddress, _withdrawRequest.tokenId);

            if (_withdrawRequest.stored) {
                // It's stored in the contract
                // Permissioned by chain

                require(_erc721TokenStorageData.owner == _withdrawRequest.reciever, "You didn't store this ERC721.");

                // Store it.
                StakingStorage.setERC721TokenStorageData(
                    _tokenAddress, _withdrawRequest.tokenId, ERC721TokenStorageData(address(0), false)
                );

                // Send it back.
                ERC721Upgradeable(_tokenAddress).transferFrom(
                    address(this), _withdrawRequest.reciever, _withdrawRequest.tokenId
                );

                emit ERC721Withdrawn(_tokenAddress, _withdrawRequest.reciever, _withdrawRequest.tokenId);
            } else {
                // Not stored
                // Permissioned by admin

                // Compute that sig is correct
                // verifyHash returns the signer of this message.
                // message is a hash of three pieces of data: nonce, tokenAddress, tokenId, and the user.
                address _signer = verifyHash(
                    keccak256(
                        abi.encodePacked(
                            _withdrawRequest.nonce,
                            _withdrawRequest.tokenAddress,
                            _withdrawRequest.tokenId,
                            _withdrawRequest.reciever
                        )
                    ),
                    _withdrawRequest.signature
                );

                require(IERC721Consumer(_tokenAddress).isAdmin(_signer), "Not a valid signed message.");

                // Make sure they aren't using sig twice.
                require(!StakingStorage.getUsedNonce(_withdrawRequest.nonce), "Nonce already used.");

                // Store nonce as used.
                StakingStorage.setUsedNonce(_withdrawRequest.nonce, true);

                // Mint the token.
                IERC721Consumer(_tokenAddress).mintFromWorld(_withdrawRequest.reciever, _withdrawRequest.tokenId);

                emit ERC721Withdrawn(_tokenAddress, _withdrawRequest.reciever, _withdrawRequest.tokenId);
            }
        }
    }

    function verifyHash(bytes32 _hash, Signature calldata _signature) internal pure returns (address) {
        bytes32 _messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));

        return ecrecover(_messageDigest, _signature.v, _signature.r, _signature.s);
    }
}

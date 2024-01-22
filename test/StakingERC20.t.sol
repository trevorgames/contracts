// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { Signature, StakingERC20, WithdrawRequest } from "../src/StakingERC20.sol";
import { ERC20Consumer } from "../src/mocks/ERC20Consumer.sol";
import { TestBase } from "./utils/TestBase.sol";

contract StakingERC20Test is TestBase {
    StakingERC20 internal staking;
    ERC20Consumer internal consumer;

    constructor() {
        vm.label(deployer, "Deployer");
    }

    function setUp() public virtual {
        staking = new StakingERC20();
        consumer = new ERC20Consumer();

        staking.initialize();
        consumer.initialize();

        consumer.setWorldAddress(address(staking));
        consumer.mintArbitrary(deployer, 2000 ether);
    }

    function testDepositsAndWithdraws2000TokensFromWorld() public {
        consumer.approve(address(staking), 2000 ether);

        assertEq(2000 ether, consumer.balanceOf(deployer));

        staking.depositERC20(address(consumer), deployer, 2000 ether);

        assertEq(0, consumer.balanceOf(deployer));

        WithdrawRequest[] memory _req = new WithdrawRequest[](1);
        _req[0] = WithdrawRequest({
            tokenAddress: address(consumer),
            reciever: deployer,
            amount: 2000 ether,
            nonce: 0,
            stored: true,
            signature: Signature(0, 0x0, 0x0)
        });
        staking.withdrawERC20(_req);

        assertEq(2000 ether, consumer.balanceOf(deployer));
    }

    function testAllowTrustedWithdraw() public {
        (address _addr, uint256 _pk) = makeAddrAndKey("trustedSigner");
        consumer.setAdmin(_addr, true);

        (uint8 _v1, bytes32 _r1, bytes32 _s1) =
            signHashEthVRS(_pk, toSigHash(0, address(consumer), 2000 ether, deployer));
        (uint8 _v2, bytes32 _r2, bytes32 _s2) =
            signHashEthVRS(_pk, toSigHash(1, address(consumer), 1000 ether, deployer));

        WithdrawRequest[] memory _req = new WithdrawRequest[](2);
        _req[0] = WithdrawRequest({
            tokenAddress: address(consumer),
            reciever: deployer,
            amount: 2000 ether,
            nonce: 0,
            stored: false,
            signature: Signature(_v1, _r1, _s1)
        });
        _req[1] = WithdrawRequest({
            tokenAddress: address(consumer),
            reciever: deployer,
            amount: 1000 ether,
            nonce: 1,
            stored: false,
            signature: Signature(_v2, _r2, _s2)
        });

        staking.withdrawERC20(_req);
        assertEq(5000 ether, consumer.balanceOf(deployer));
    }

    function toSigHash(
        uint256 _nonce,
        address _token,
        uint256 _amount,
        address _recipient
    )
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_nonce, _token, _amount, _recipient));
    }
}

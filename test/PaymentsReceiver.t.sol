// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { ERC1155HolderUpgradeable } from
    "@openzeppelin/contracts-diamond/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-diamond/token/ERC721/ERC721Upgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-diamond/token/ERC20/IERC20Upgradeable.sol";
import { AddressUpgradeable } from "@openzeppelin/contracts-diamond/utils/AddressUpgradeable.sol";

import { TestBase } from "./utils/TestBase.sol";
import { DiamondManager, Diamond, IDiamondCut, FacetInfo } from "./utils/DiamondManager.sol";
import { DiamondUtils } from "./utils/DiamondUtils.sol";
import { ERC20MockDecimals } from "test/mocks/ERC20MockDecimals.sol";

import { LibAccessControlRoles, ADMIN_ROLE, ADMIN_GRANTER_ROLE } from "src/libraries/LibAccessControlRoles.sol";
import { LibMeta } from "src/libraries/LibMeta.sol";

import { MockV3Aggregator } from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import { PaymentsFacet } from "src/payments/PaymentsFacet.sol";
import { PaymentsReceiver } from "src/payments/PaymentsReceiver.sol";

contract PaymentsReceiverTest is TestBase, DiamondManager, ERC1155HolderUpgradeable {
    using DiamondUtils for Diamond;
    using AddressUpgradeable for address;

    PaymentsFacet internal payments;

    MockV3Aggregator internal ethUsdPriceFeed;
    MockV3Aggregator internal trvUsdPriceFeed;
    MockV3Aggregator internal trvEthPriceFeed;
    MockV3Aggregator internal ethTrvPriceFeed;
    // Taken from the ETH / USD price feed when this test was written and 1 ETH equaled 1758.71877553 USD
    // Stored in 8 decimal places because it's USD
    int256 public usdToEthPrice = 175_871_877_553;
    // Taken from the TRV / USD price feed when this test was written and 1 TRV equaled 1.98940930 USD
    // Stored in 8 decimal places because it's USD
    int256 public trvToUsdPrice = 198_940_930;
    // Stored in 18 decimal places because it's ETH
    int256 public trvToEthPrice = 0.001103 ether;
    // Stored in 18 decimal places because it's TRV
    int256 public ethToTrvPrice = 906.84 ether;

    ERC20MockDecimals internal mockUSDC = new ERC20MockDecimals(6);
    ERC20MockDecimals internal mockWETH = new ERC20MockDecimals(18);
    ERC20MockDecimals internal mockTrv = new ERC20MockDecimals(18);

    function setUp() public {
        ethUsdPriceFeed = new MockV3Aggregator(8, usdToEthPrice);
        payments = new PaymentsFacet();
        payments.PaymentsFacet_init(address(ethUsdPriceFeed), address(mockTrv));
    }

    function testAllowTakePaymentERC20() public { }
}

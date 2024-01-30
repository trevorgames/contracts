// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { ERC1155HolderUpgradeable } from
    "@openzeppelin/contracts-diamond/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import { AddressUpgradeable } from "@openzeppelin/contracts-diamond/utils/AddressUpgradeable.sol";

import { TestBase } from "./utils/TestBase.sol";
import { DiamondManager, Diamond, IDiamondCut, FacetInfo } from "./utils/DiamondManager.sol";
import { DiamondUtils } from "./utils/DiamondUtils.sol";
import { ERC20MockDecimals } from "test/mocks/ERC20MockDecimals.sol";
import { MockPaymentsReceiver } from "test/mocks/MockPaymentsReceiver.sol";

import { LibAccessControlRoles, ADMIN_ROLE, ADMIN_GRANTER_ROLE } from "src/libraries/LibAccessControlRoles.sol";
import { LibMeta } from "src/libraries/LibMeta.sol";

import { MockV3Aggregator } from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import { PaymentsFacet } from "src/payments/PaymentsFacet.sol";
import { PaymentsStorage, PriceType } from "src/payments/PaymentsStorage.sol";
import { PaymentsReceiver } from "src/payments/PaymentsReceiver.sol";

contract PaymentFacetInit {
    function init(address _usdc, address _usdt) external {
        PaymentsStorage.Layout storage _layout = PaymentsStorage.layout();
        _layout.usdcAddress = _usdc;
        _layout.usdtAddress = _usdt;
    }
}

contract PaymentsFacetV2Test is TestBase, DiamondManager, ERC1155HolderUpgradeable {
    using DiamondUtils for Diamond;
    using AddressUpgradeable for address;

    // Events copied from other contracts for testing
    event PaymentSent(address payor, address token, uint256 amount, address paymentsReceiver);
    event PaymentReceived(
        address payor,
        address paymentERC20,
        uint256 paymentAmount,
        uint256 paymentAmountInPricedToken,
        PriceType priceType,
        address pricedERC20
    );

    PaymentsFacet internal payments;
    MockPaymentsReceiver internal receiver;
    address internal receiverAddress;

    MockV3Aggregator internal ethUsdPriceFeed;
    MockV3Aggregator internal trvUsdPriceFeed;
    MockV3Aggregator internal trvEthPriceFeed;
    MockV3Aggregator internal ethTrvPriceFeed;
    // Taken from the ETH / USD price feed when this test was written and 1 ETH equaled 1758.71877553 USD
    // Stored in 8 decimal places because it's USD
    int256 public usdToEthPrice = 175_871_877_553;
    // Taken from the TRV / USD price feed when this test was written and 1 TRV equaled 1.98940930 USD
    // Stored in 8 decimal places because it's USD
    int256 public usdToTrvPrice = 198_940_930;
    // Stored in 18 decimal places because it's ETH
    int256 public ethToTrvPrice = 0.001103 ether;
    // Stored in 18 decimal places because it's TRV
    int256 public trvToEthPrice = 906.84 ether;

    ERC20MockDecimals internal mockUSDC = new ERC20MockDecimals(6);
    ERC20MockDecimals internal mockUSDT = new ERC20MockDecimals(6);
    ERC20MockDecimals internal mockWETH = new ERC20MockDecimals(18);
    ERC20MockDecimals internal mockTrv = new ERC20MockDecimals(18);

    function setUp() public {
        ethUsdPriceFeed = new MockV3Aggregator(8, usdToEthPrice);
        trvUsdPriceFeed = new MockV3Aggregator(8, usdToTrvPrice);
        trvEthPriceFeed = new MockV3Aggregator(18, ethToTrvPrice);
        ethTrvPriceFeed = new MockV3Aggregator(18, trvToEthPrice);

        FacetInfo[] memory _facetInfo = new FacetInfo[](1);
        Diamond.Initialization[] memory _initializations = new Diamond.Initialization[](2);

        _facetInfo[0] = FacetInfo(address(new PaymentsFacet()), "PaymentsFacet", IDiamondCut.FacetCutAction.Add);
        _initializations[0] = Diamond.Initialization({
            initContract: _facetInfo[0].addr,
            initData: abi.encodeWithSelector(
                PaymentsFacet.PaymentsFacet_init.selector, address(ethUsdPriceFeed), address(mockTrv)
                )
        });
        _initializations[1] = Diamond.Initialization({
            initContract: address(new PaymentFacetInit()),
            initData: abi.encodeWithSelector(PaymentFacetInit.init.selector, address(mockUSDC), address(mockUSDT))
        });

        init(_facetInfo, _initializations);

        payments = PaymentsFacet(address(diamond));
        payments.initializeERC20(
            address(mockTrv), 18, address(trvEthPriceFeed), address(trvUsdPriceFeed), new address[](0), new address[](0)
        );
        payments.setERC20PriceFeedForGasToken(address(mockTrv), address(ethTrvPriceFeed));

        receiver = new MockPaymentsReceiver();
        receiver.initialize(address(payments));
        receiverAddress = address(receiver);
    }
}

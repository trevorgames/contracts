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

contract PaymentsFacetTest is TestBase, DiamondManager, ERC1155HolderUpgradeable {
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

    function testStateInitializedCorrectly() public {
        assertEq(address(payments.getTrvAddress()), address(mockTrv));
    }

    function testCannotCallFunctionsBeforeInit() public {
        payments = new PaymentsFacet();

        // Non-contract recipient
        vm.expectRevert(err(PaymentsStorage.NonPaymentsReceiverRecipient.selector, leet));
        payments.makeStaticGasTokenPayment(leet, 1 ether);
        vm.expectRevert(err(PaymentsStorage.NonPaymentsReceiverRecipient.selector, leet));
        payments.makeStaticERC20Payment(leet, address(mockTrv), 1 ether);
        vm.expectRevert(err(PaymentsStorage.NonPaymentsReceiverRecipient.selector, leet));
        payments.makeERC20PaymentByPriceType(leet, address(mockTrv), 1 ether, PriceType.STATIC, address(0));
        vm.expectRevert(err(PaymentsStorage.NonPaymentsReceiverRecipient.selector, leet));
        payments.makeGasTokenPaymentByPriceType(leet, 1 ether, PriceType.STATIC, address(0));

        // Contract recipient that doesn't have the supportsInterface function
        vm.prank(leet);
        vm.expectRevert(err(PaymentsStorage.NonPaymentsReceiverRecipient.selector, deployer));
        payments.makeStaticGasTokenPayment(deployer, 1 ether);

        // Contract recipient that has the supportsInterface function but doesn't support PaymentsReceiver
        vm.prank(leet);
        vm.expectRevert(err(PaymentsStorage.NonPaymentsReceiverRecipient.selector, address(mockTrv)));
        payments.makeStaticGasTokenPayment(address(mockTrv), 1 ether);
    }

    function testCalculateStaticPaymentAmountsCorrectly() public {
        uint256 _expectedAmount = 150; // Amount before accounting for token decimals

        uint256 _trvPaymentAmount = payments.calculatePaymentAmountByPriceType(
            address(mockTrv), _expectedAmount * 10 ** 18, PriceType.STATIC, address(0)
        );
        uint256 _usdcPaymentAmount = payments.calculatePaymentAmountByPriceType(
            address(mockUSDC), _expectedAmount * 10 ** 6, PriceType.STATIC, address(0)
        );
        uint256 _gasTokenPaymentAmount = payments.calculatePaymentAmountByPriceType(
            address(0), _expectedAmount * 10 ** 18, PriceType.STATIC, address(0)
        );

        assertEq(_trvPaymentAmount, _expectedAmount * 10 ** 18);
        assertEq(_usdcPaymentAmount, _expectedAmount * 10 ** 6);
        assertEq(_gasTokenPaymentAmount, _expectedAmount * 10 ** 18);
    }

    function testCalculateGasTokenByPriceTypeCorrectly() public {
        uint256 _usdAmount = 1000 * 10 ** 8; // 1000 USD
        uint256 _trvAmount = 500 * 10 ** 18; // 500 TRV

        uint256 _expectedGasTokenAmountFromUSD = _usdAmount * 10 ** 18 / uint256(usdToEthPrice); // Convert to 18
            // decimals before converting
        uint256 _expectedGasTokenAmountFromTrv = _trvAmount * 10 ** 18 / uint256(trvToEthPrice); // Increase decimals to
            // allow for division back to 18 decimals

        uint256 _gasTokenUSDAmount =
            payments.calculatePaymentAmountByPriceType(address(0), _usdAmount, PriceType.PRICED_IN_USD, address(0));
        uint256 _gasTokenTrvAmount = payments.calculatePaymentAmountByPriceType(
            address(0), _trvAmount, PriceType.PRICED_IN_ERC20, address(mockTrv)
        );

        assertEq(_gasTokenUSDAmount, _expectedGasTokenAmountFromUSD);
        assertEq(_gasTokenTrvAmount, _expectedGasTokenAmountFromTrv);
    }

    function testCalculateERC20ByPriceTypeCorrectly() public {
        uint256 _usdAmount = 1000 * 10 ** 8; // 1000 USD
        uint256 _gasTokenAmount = 0.5 ether; // 0.5 ETH

        uint256 _expectedTrvAmountFromUSD = _usdAmount * 10 ** 18 / uint256(usdToTrvPrice); // Convert to 18 decimals
            // before converting
        uint256 _expectedTrvAmountFromGasToken = _gasTokenAmount * 10 ** 18 / uint256(ethToTrvPrice); // Increase
            // decimals to allow for division back to 18 decimals

        uint256 _trvUSDAmount = payments.calculatePaymentAmountByPriceType(
            address(mockTrv), _usdAmount, PriceType.PRICED_IN_USD, address(0)
        );
        uint256 _trvGasTokenAmount = payments.calculatePaymentAmountByPriceType(
            address(mockTrv), _gasTokenAmount, PriceType.PRICED_IN_GAS_TOKEN, address(0)
        );

        assertEq(_trvUSDAmount, _expectedTrvAmountFromUSD);
        assertEq(_trvGasTokenAmount, _expectedTrvAmountFromGasToken);
    }

    function testRevertCalculateInvalidUsdToken() public {
        vm.expectRevert(err(PaymentsStorage.InvalidUsdToken.selector, address(mockTrv)));
        payments.calculateUsdPaymentAmountByPricedToken(address(mockTrv), 1 ether, address(mockUSDC));
    }

    function testCalculateUSDByPricedToken() public {
        uint256 _trvAmount = 10 ether;
        uint256 _expectedUSDAmount = _trvAmount * uint256(usdToTrvPrice) / 10 ** 18;

        uint256 _usdAmount =
            payments.calculateUsdPaymentAmountByPricedToken(address(mockUSDC), _trvAmount, address(mockTrv));

        assertEq(_usdAmount, _expectedUSDAmount);
    }

    function testIsValidPriceType() public {
        assertTrue(payments.isValidPriceType(address(mockTrv), PriceType.STATIC, address(0)));
        assertTrue(payments.isValidPriceType(address(mockTrv), PriceType.PRICED_IN_USD, address(0)));
        assertTrue(payments.isValidPriceType(address(mockTrv), PriceType.PRICED_IN_GAS_TOKEN, address(0)));
        assertTrue(payments.isValidPriceType(address(0), PriceType.STATIC, address(0)));
        assertTrue(payments.isValidPriceType(address(0), PriceType.PRICED_IN_USD, address(0)));
        assertTrue(payments.isValidPriceType(address(0), PriceType.PRICED_IN_ERC20, address(mockTrv)));
        assertTrue(payments.isValidPriceType(address(mockTrv), PriceType.PRICED_IN_ERC20, address(mockTrv)));
        assertTrue(payments.isValidPriceType(address(0), PriceType.PRICED_IN_GAS_TOKEN, address(0)));
        assertFalse(payments.isValidPriceType(address(mockTrv), PriceType.PRICED_IN_ERC20, address(mockUSDC)));
        assertFalse(payments.isValidPriceType(address(0), PriceType.PRICED_IN_ERC20, address(mockUSDC)));
        assertFalse(payments.isValidPriceType(address(mockUSDC), PriceType.PRICED_IN_USD, address(0)));
        assertFalse(payments.isValidPriceType(address(mockUSDC), PriceType.PRICED_IN_GAS_TOKEN, address(0)));
        assertFalse(payments.isValidPriceType(address(mockUSDC), PriceType.PRICED_IN_ERC20, address(mockTrv)));
        assertFalse(payments.isValidPriceType(address(mockTrv), PriceType.PRICED_IN_ERC20, address(mockUSDC)));
    }

    function testStaticPaymentsCorrect() public {
        uint256 _paymentAmount = 100 ether;
        vm.deal(deployer, _paymentAmount);
        mockTrv.mint(deployer, _paymentAmount);
        mockTrv.approve(address(payments), _paymentAmount);

        assertEq(receiverAddress.balance, 0);
        assertEq(mockTrv.balanceOf(receiverAddress), 0);

        vm.expectCall(
            receiverAddress,
            abi.encodeWithSelector(
                PaymentsReceiver.acceptGasToken.selector,
                deployer,
                _paymentAmount,
                _paymentAmount,
                PriceType.STATIC,
                address(0)
            )
        );
        vm.expectEmit(true, true, false, true, receiverAddress);
        emit PaymentReceived(deployer, address(0), _paymentAmount, _paymentAmount, PriceType.STATIC, address(0));
        payments.makeStaticGasTokenPayment{ value: _paymentAmount }(receiverAddress, _paymentAmount);

        payments.makeStaticERC20Payment(receiverAddress, address(mockTrv), _paymentAmount);

        assertEq(receiverAddress.balance, _paymentAmount);
        assertEq(mockTrv.balanceOf(receiverAddress), _paymentAmount);
    }

    function testMakeUsdPaymentByPricedToken() public {
        uint256 _trvAmount = 10 ether;
        uint256 _paymentAmount = _trvAmount * uint256(usdToTrvPrice) / 10 ** 18;

        vm.deal(deployer, _paymentAmount);
        mockUSDC.mint(deployer, _paymentAmount);
        mockUSDC.approve(address(payments), _paymentAmount);

        assertEq(mockUSDC.balanceOf(receiverAddress), 0);

        vm.expectCall(
            receiverAddress,
            abi.encodeWithSelector(
                PaymentsReceiver.acceptERC20.selector,
                deployer,
                address(mockUSDC),
                _paymentAmount,
                _trvAmount,
                PriceType.PRICED_IN_ERC20,
                address(mockTrv)
            )
        );
        vm.expectEmit(true, true, false, true, receiverAddress);
        emit PaymentReceived(
            deployer, address(mockUSDC), _paymentAmount, _trvAmount, PriceType.PRICED_IN_ERC20, address(mockTrv)
        );
        payments.makeUsdPaymentByPricedToken(receiverAddress, address(mockUSDC), _trvAmount, address(mockTrv));
    }
}

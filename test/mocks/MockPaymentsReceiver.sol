// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PaymentsReceiver } from "src/payments/PaymentsReceiver.sol";

/**
 * @notice Workaround for the lack of vm.expectCall to internal function support in Foundry.
 *         Used to check emissions of the internal functions with correct argument values.
 */
contract MockPaymentsReceiver is PaymentsReceiver {
    event AcceptStaticTrv(address payor, uint256 paymentAmount);
    event AcceptTrvPricedInUSD(address payor, uint256 paymentAmount, uint256 priceInUSD);
    event AcceptTrvPricedInGasToken(address payor, uint256 paymentAmount, uint256 priceInGasToken);
    event AcceptTrvPricedInERC20(address payor, uint256 paymentAmount, address pricedERC20, uint256 priceInERC20);
    event AcceptGasTokenPricedInTrv(address payor, uint256 paymentAmount, uint256 priceInTrv);
    event AcceptERC20PricedInTrv(address payor, address paymentERC20, uint256 paymentAmount, uint256 priceInTrv);

    event AcceptStaticERC20(address payor, address paymentERC20, uint256 paymentAmount);
    event AcceptERC20PricedInERC20(
        address payor, address paymentERC20, uint256 paymentAmount, address pricedERC20, uint256 priceInERC20
    );
    event AcceptERC20PricedInUSD(address payor, address paymentERC20, uint256 paymentAmount, uint256 priceInUSD);
    event AcceptERC20PricedInGasToken(
        address payor, address paymentERC20, uint256 paymentAmount, uint256 priceInGasToken
    );

    event AcceptStaticGasToken(address payor, uint256 paymentAmount);
    event AcceptGasTokenPricedInERC20(address payor, uint256 paymentAmount, address pricedERC20, uint256 priceInERC20);
    event AcceptGasTokenPricedInUSD(address payor, uint256 paymentAmount, uint256 priceInUSD);

    function initialize(address _spellcasterPayments) external {
        PaymentsReceiver.PaymentsReceiver_init(_spellcasterPayments);
    }

    function _acceptStaticTrvPayment(address _payor, uint256 _paymentAmount) internal override {
        emit AcceptStaticTrv(_payor, _paymentAmount);
    }

    function _acceptTrvPaymentPricedInUSD(
        address _payor,
        uint256 _paymentAmount,
        uint256 _priceInUSD
    )
        internal
        override
    {
        emit AcceptTrvPricedInUSD(_payor, _paymentAmount, _priceInUSD);
    }

    function _acceptTrvPaymentPricedInGasToken(
        address _payor,
        uint256 _paymentAmount,
        uint256 _priceInGasToken
    )
        internal
        override
    {
        emit AcceptTrvPricedInGasToken(_payor, _paymentAmount, _priceInGasToken);
    }

    function _acceptTrvPaymentPricedInERC20(
        address _payor,
        uint256 _paymentAmount,
        address _pricedERC20,
        uint256 _priceInERC20
    )
        internal
        override
    {
        emit AcceptTrvPricedInERC20(_payor, _paymentAmount, _pricedERC20, _priceInERC20);
    }

    function _acceptGasTokenPaymentPricedInTrv(
        address _payor,
        uint256 _paymentAmount,
        uint256 _priceInTrv
    )
        internal
        override
    {
        emit AcceptGasTokenPricedInTrv(_payor, _paymentAmount, _priceInTrv);
    }

    function _acceptStaticERC20Payment(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount
    )
        internal
        override
    {
        emit AcceptStaticERC20(_payor, _paymentERC20, _paymentAmount);
    }

    function _acceptERC20PaymentPricedInERC20(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount,
        address _pricedERC20,
        uint256 _priceInERC20
    )
        internal
        override
    {
        emit AcceptERC20PricedInERC20(_payor, _paymentERC20, _paymentAmount, _pricedERC20, _priceInERC20);
    }

    function _acceptERC20PaymentPricedInUSD(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount,
        uint256 _priceInUSD
    )
        internal
        override
    {
        emit AcceptERC20PricedInUSD(_payor, _paymentERC20, _paymentAmount, _priceInUSD);
    }

    function _acceptERC20PaymentPricedInTrv(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount,
        uint256 _priceInTrv
    )
        internal
        override
    {
        emit AcceptERC20PricedInTrv(_payor, _paymentERC20, _paymentAmount, _priceInTrv);
    }

    function _acceptERC20PaymentPricedInGasToken(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount,
        uint256 _priceInGasToken
    )
        internal
        override
    {
        emit AcceptERC20PricedInGasToken(_payor, _paymentERC20, _paymentAmount, _priceInGasToken);
    }

    function _acceptStaticGasTokenPayment(address _payor, uint256 _paymentAmount) internal override {
        emit AcceptStaticGasToken(_payor, _paymentAmount);
    }

    function _acceptGasTokenPaymentPricedInUSD(
        address _payor,
        uint256 _paymentAmount,
        uint256 _priceInUSD
    )
        internal
        override
    {
        emit AcceptGasTokenPricedInUSD(_payor, _paymentAmount, _priceInUSD);
    }

    function _acceptGasTokenPaymentPricedInERC20(
        address _payor,
        uint256 _paymentAmount,
        address _pricedERC20,
        uint256 _priceInERC20
    )
        internal
        override
    {
        emit AcceptGasTokenPricedInERC20(_payor, _paymentAmount, _pricedERC20, _priceInERC20);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC165Upgradeable } from "@openzeppelin/contracts-diamond/utils/introspection/IERC165Upgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-diamond/token/ERC20/IERC20Upgradeable.sol";

import { FacetInitializable } from "src/utils/FacetInitializable.sol";
import { LibMeta } from "src/libraries/LibMeta.sol";

import { IPayments, PriceType } from "src/interfaces/IPayments.sol";
import { IPaymentsReceiver } from "src/interfaces/IPaymentsReceiver.sol";
import { PaymentsReceiverStorage } from "src/payments/PaymentsReceiverStorage.sol";

/**
 * @title Payments Receiver contract.
 * @dev This facet exposes functionality to easily allow developers to accept payments in ERC20 tokens or gas
 *      tokens (ETH, MATIC, etc.). Developers can also accept payment in a token amount priced in USD, other ERC20, or
 * gas tokens.
 */
contract PaymentsReceiver is FacetInitializable, IPaymentsReceiver, IERC165Upgradeable {
    /**
     * @dev Initialize the facet. Must be called before any other functions.
     */
    function PaymentsReceiver_init(address _spellcasterPayments)
        public
        facetInitializer(keccak256("PaymentsReceiver"))
    {
        PaymentsReceiverStorage.layout().spellcasterPayments = IPayments(_spellcasterPayments);
    }

    /**
     * @inheritdoc IPaymentsReceiver
     */
    function acceptERC20(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedERC20
    )
        external
        override
        onlySpellcasterPayments
    {
        emit PaymentReceived(
            _payor, _paymentERC20, _paymentAmount, _paymentAmountInPricedToken, _priceType, _pricedERC20
        );
        _acceptERC20(_payor, _paymentERC20, _paymentAmount, _paymentAmountInPricedToken, _priceType, _pricedERC20);
    }

    /**
     * @inheritdoc IPaymentsReceiver
     */
    function acceptGasToken(
        address _payor,
        uint256 _paymentAmount,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedERC20
    )
        external
        payable
        override
        onlySpellcasterPayments
    {
        emit PaymentReceived(_payor, address(0), _paymentAmount, _paymentAmountInPricedToken, _priceType, _pricedERC20);
        _acceptGasToken(_payor, _paymentAmount, _paymentAmountInPricedToken, _priceType, _pricedERC20);
    }

    /* solhint-disable code-complexity */
    function _acceptERC20(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedERC20
    )
        internal
    {
        if (
            _priceType == PriceType.STATIC || (_priceType == PriceType.PRICED_IN_ERC20 && _pricedERC20 == _paymentERC20)
        ) {
            if (_paymentAmount != _paymentAmountInPricedToken) {
                revert PaymentsReceiverStorage.IncorrectPaymentAmount(_paymentAmount, _paymentAmountInPricedToken);
            }
            if (_paymentERC20 == PaymentsReceiverStorage.layout().spellcasterPayments.getTrvAddress()) {
                _acceptStaticTrvPayment(_payor, _paymentAmount);
            } else {
                _acceptStaticERC20Payment(_payor, _paymentERC20, _paymentAmount);
            }
        } else if (_priceType == PriceType.PRICED_IN_ERC20) {
            if (_pricedERC20 == PaymentsReceiverStorage.layout().spellcasterPayments.getTrvAddress()) {
                _acceptERC20PaymentPricedInTrv(_payor, _paymentERC20, _paymentAmount, _paymentAmountInPricedToken);
            } else if (_paymentERC20 == PaymentsReceiverStorage.layout().spellcasterPayments.getTrvAddress()) {
                _acceptTrvPaymentPricedInERC20(_payor, _paymentAmount, _pricedERC20, _paymentAmountInPricedToken);
            } else {
                _acceptERC20PaymentPricedInERC20(
                    _payor, _paymentERC20, _paymentAmount, _pricedERC20, _paymentAmountInPricedToken
                );
            }
        } else if (_priceType == PriceType.PRICED_IN_USD) {
            if (_paymentERC20 == PaymentsReceiverStorage.layout().spellcasterPayments.getTrvAddress()) {
                _acceptTrvPaymentPricedInUSD(_payor, _paymentAmount, _paymentAmountInPricedToken);
            } else {
                _acceptERC20PaymentPricedInUSD(_payor, _paymentERC20, _paymentAmount, _paymentAmountInPricedToken);
            }
        } else if (_priceType == PriceType.PRICED_IN_GAS_TOKEN) {
            if (_paymentERC20 == PaymentsReceiverStorage.layout().spellcasterPayments.getTrvAddress()) {
                _acceptTrvPaymentPricedInGasToken(_payor, _paymentAmount, _paymentAmountInPricedToken);
            } else {
                _acceptERC20PaymentPricedInGasToken(_payor, _paymentERC20, _paymentAmount, _paymentAmountInPricedToken);
            }
        } else {
            revert PaymentsReceiverStorage.PaymentTypeNotAccepted("ERC20");
        }
    }

    function _acceptGasToken(
        address _payor,
        uint256 _paymentAmount,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedERC20
    )
        internal
    {
        if (msg.value != _paymentAmount) {
            revert PaymentsReceiverStorage.IncorrectPaymentAmount(msg.value, _paymentAmountInPricedToken);
        }
        if (_priceType == PriceType.STATIC) {
            if (msg.value != _paymentAmountInPricedToken || _paymentAmount != _paymentAmountInPricedToken) {
                revert PaymentsReceiverStorage.IncorrectPaymentAmount(msg.value, _paymentAmountInPricedToken);
            }
            _acceptStaticGasTokenPayment(_payor, msg.value);
        } else if (_priceType == PriceType.PRICED_IN_ERC20) {
            if (_pricedERC20 == PaymentsReceiverStorage.layout().spellcasterPayments.getTrvAddress()) {
                _acceptGasTokenPaymentPricedInTrv(_payor, _paymentAmount, _paymentAmountInPricedToken);
            } else {
                _acceptGasTokenPaymentPricedInERC20(_payor, _paymentAmount, _pricedERC20, _paymentAmountInPricedToken);
            }
        } else if (_priceType == PriceType.PRICED_IN_USD) {
            _acceptGasTokenPaymentPricedInUSD(_payor, _paymentAmount, _paymentAmountInPricedToken);
        } else {
            revert PaymentsReceiverStorage.PaymentTypeNotAccepted("Gas Token");
        }
    }

    function _acceptStaticTrvPayment(address _payor, uint256 _paymentAmount) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("TRV ", string(abi.encode(_payor, _paymentAmount)))
        );
    }

    function _acceptTrvPaymentPricedInUSD(
        address _payor,
        uint256 _paymentAmount,
        uint256 _priceInUSD
    )
        internal
        virtual
    {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("TRV / USD ", string(abi.encode(_payor, _paymentAmount, _priceInUSD)))
        );
    }

    function _acceptTrvPaymentPricedInGasToken(
        address _payor,
        uint256 _paymentAmount,
        uint256 _priceInGasToken
    )
        internal
        virtual
    {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("TRV / GAS TOKEN ", string(abi.encode(_payor, _paymentAmount, _priceInGasToken)))
        );
    }

    function _acceptTrvPaymentPricedInERC20(
        address _payor,
        uint256 _paymentAmount,
        address _pricedERC20,
        uint256 _priceInERC20
    )
        internal
        virtual
    {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("TRV / ERC20 ", string(abi.encode(_payor, _paymentAmount, _pricedERC20, _priceInERC20)))
        );
    }

    function _acceptGasTokenPaymentPricedInTrv(
        address _payor,
        uint256 _paymentAmount,
        uint256 _priceInTrv
    )
        internal
        virtual
    {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("GAS TOKEN / TRV ", string(abi.encode(_payor, _paymentAmount, _priceInTrv)))
        );
    }

    function _acceptStaticERC20Payment(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount
    )
        internal
        virtual
    {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("ERC20 ", string(abi.encode(_payor, _paymentERC20, _paymentAmount)))
        );
    }

    function _acceptERC20PaymentPricedInERC20(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount,
        address _pricedERC20,
        uint256 _priceInERC20
    )
        internal
        virtual
    {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat(
                "ERC20 / ERC20 ", string(abi.encode(_payor, _paymentERC20, _paymentAmount, _pricedERC20, _priceInERC20))
            )
        );
    }

    function _acceptERC20PaymentPricedInUSD(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount,
        uint256 _priceInUSD
    )
        internal
        virtual
    {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("ERC20 / USD ", string(abi.encode(_payor, _paymentERC20, _paymentAmount, _priceInUSD)))
        );
    }

    function _acceptERC20PaymentPricedInTrv(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount,
        uint256 _priceInTrv
    )
        internal
        virtual
    {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("ERC20 / TRV ", string(abi.encode(_payor, _paymentERC20, _paymentAmount, _priceInTrv)))
        );
    }

    function _acceptERC20PaymentPricedInGasToken(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount,
        uint256 _priceInGasToken
    )
        internal
        virtual
    {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat(
                "ERC20 / GAS TOKEN ", string(abi.encode(_payor, _paymentERC20, _paymentAmount, _priceInGasToken))
            )
        );
    }

    function _acceptStaticGasTokenPayment(address _payor, uint256 _paymentAmount) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("GAS TOKEN ", string(abi.encode(_payor, _paymentAmount)))
        );
    }

    function _acceptGasTokenPaymentPricedInUSD(
        address _payor,
        uint256 _paymentAmount,
        uint256 _priceInUSD
    )
        internal
        virtual
    {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("GAS TOKEN / USD ", string(abi.encode(_payor, _paymentAmount, _priceInUSD)))
        );
    }

    function _acceptGasTokenPaymentPricedInERC20(
        address _payor,
        uint256 _paymentAmount,
        address _pricedERC20,
        uint256 _priceInERC20
    )
        internal
        virtual
    {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("GAS TOKEN / ERC20 ", string(abi.encode(_payor, _paymentAmount, _pricedERC20, _priceInERC20)))
        );
    }

    /**
     * @dev Enables external contracts to query if this contract implements the IPaymentsReceiver interface.
     *      Needed for compliant implementation of Spellcaster Payments.
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IPaymentsReceiver).interfaceId || _interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev Modifier to make a function callable only by the Spellcaster Payments contract.
     */
    modifier onlySpellcasterPayments() {
        if (LibMeta._msgSender() != address(PaymentsReceiverStorage.layout().spellcasterPayments)) {
            revert PaymentsReceiverStorage.SenderNotSpellcasterPayments(LibMeta._msgSender());
        }
        _;
    }
}

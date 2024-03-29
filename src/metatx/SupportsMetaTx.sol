// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.16;

import { ECDSAUpgradeable } from "@openzeppelin/contracts-diamond/utils/cryptography/ECDSAUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-diamond/utils/cryptography/EIP712Upgradeable.sol";

import { FacetInitializable } from "src/utils/FacetInitializable.sol";
import { LibAccessControlRoles } from "src/libraries/LibAccessControlRoles.sol";
import { LibUtilities } from "src/libraries/LibUtilities.sol";

import {
    MetaTxFacetStorage, ForwardRequest, ISystemDelegateApprover, FORWARD_REQ_TYPEHASH
} from "./MetaTxFacetStorage.sol";

abstract contract SupportsMetaTx is FacetInitializable, EIP712Upgradeable {
    using ECDSAUpgradeable for bytes32;

    /**
     * @dev Sets all necessary state and permissions for the contract. Assumed to be called from an initializing script
     * instead of a facet
     * @param _organizationDelegateApprover The delegate approver address that tracks which wallet can run txs on
     *  behalf of the real sending account
     */
    function __SupportsMetaTx_init(address _organizationDelegateApprover) internal onlyFacetInitializing {
        if (_organizationDelegateApprover == address(0)) {
            revert MetaTxFacetStorage.InvalidDelegateApprover();
        }
        __EIP712_init("Spellcaster", "1.0.0");

        MetaTxFacetStorage.layout().systemDelegateApprover = ISystemDelegateApprover(_organizationDelegateApprover);
    }

    /**
     * @dev Verifies and consumes the session ID, ensuring it matches the provided organization ID.
     *      If the call is from a meta transaction, the session ID is consumed and must match the organization ID.
     *      Resets the session ID before the call to ensure that subsequent calls do not keep validating.
     * @param _organizationId The organization ID to be verified against the session ID
     */
    function verifyAndConsumeSessionId(bytes32 _organizationId) internal {
        MetaTxFacetStorage.Layout storage _l = MetaTxFacetStorage.layout();
        bytes32 _sessionId = _l.sessionOrganizationId;

        if (_sessionId != "") {
            if (_sessionId != _organizationId) {
                revert MetaTxFacetStorage.SessionOrganizationIdMismatch(_sessionId, _organizationId);
            }

            _l.sessionOrganizationId = "";
        }
    }

    /**
     * @dev Returns the session organization ID from the MetaTxFacetStorage layout.
     * @return sessionId_ The session organization ID
     */
    function getSessionOrganizationId() internal view returns (bytes32 sessionId_) {
        sessionId_ = MetaTxFacetStorage.layout().sessionOrganizationId;
    }

    modifier supportsMetaTx(bytes32 _organizationId) virtual {
        MetaTxFacetStorage.Layout storage _l = MetaTxFacetStorage.layout();
        bytes32 _sessionId = _l.sessionOrganizationId;
        // If the call is from a meta tx, consume the session id and require it to match
        if (_sessionId != "") {
            if (_sessionId != _organizationId) {
                revert MetaTxFacetStorage.SessionOrganizationIdMismatch(_sessionId, _organizationId);
            }
            // Reset the session id before the call to ensure that subsequent calls do not keep validating
            _l.sessionOrganizationId = "";
        }
        _;
    }

    modifier supportsMetaTxNoId() virtual {
        _;

        MetaTxFacetStorage.Layout storage _l = MetaTxFacetStorage.layout();
        // If the call is from a meta tx, consume the session id
        if (_l.sessionOrganizationId != "") {
            // Reset the session id after the call to ensure that a subsequent call will validate the session id if
            // applicable
            _l.sessionOrganizationId = "";
        }
    }
}

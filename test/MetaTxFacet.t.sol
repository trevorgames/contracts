// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { ERC1155HolderUpgradeable } from
    "@openzeppelin/contracts-diamond/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import { AddressUpgradeable } from "@openzeppelin/contracts-diamond/utils/AddressUpgradeable.sol";

import { TestBase } from "./utils/TestBase.sol";
import { DiamondManager, Diamond, IDiamondCut, FacetInfo } from "./utils/DiamondManager.sol";
import { DiamondUtils } from "./utils/DiamondUtils.sol";

import { AccessControlFacet } from "src/access/AccessControlFacet.sol";
import { ERC1155Facet } from "src/token/ERC1155Facet.sol";
import { MetaTxFacet } from "src/metatx/MetaTxFacet.sol";
import {
    MetaTxFacetStorage,
    ISystemDelegateApprover,
    ForwardRequest,
    FORWARD_REQ_TYPEHASH
} from "src/metatx/MetaTxFacetStorage.sol";
import { LibAccessControlRoles, ADMIN_ROLE, ADMIN_GRANTER_ROLE } from "src/libraries/LibAccessControlRoles.sol";
import { LibMeta } from "../src/libraries/LibMeta.sol";

contract MetaTxImpl is MetaTxFacet, AccessControlFacet, ERC1155Facet {
    function initialize(address _systemDelegateApprover) external facetInitializer(keccak256("MetaTxImpl")) {
        _setRoleAdmin(ADMIN_ROLE, ADMIN_GRANTER_ROLE);
        _grantRole(ADMIN_ROLE, LibMeta._msgSender());
        _grantRole(ADMIN_GRANTER_ROLE, LibMeta._msgSender());
        __MetaTxFacet_init();
        __SupportsMetaTx_init(_systemDelegateApprover);
    }

    /**
     * @dev Overrides the _msgSender function for all dependent contracts that implement it.
     *  This must be done outside of the OZ-wrapped facets to avoid conflicting overrides needing explicit declaration.
     *  This implementation is needed to test that dependent facet contracts are using the correct _msgSender
     */
    function _msgSender() internal view override returns (address) {
        return LibMeta._msgSender();
    }

    function adminMint(uint256 _id, uint256 _amount) external onlyRole(ADMIN_ROLE) supportsMetaTxNoId {
        _mint(_msgSender(), _id, _amount, "");
    }

    function adminMintForOrg(
        bytes32 _organizationId,
        uint256 _id,
        uint256 _amount
    )
        external
        onlyRole(ADMIN_ROLE)
        supportsMetaTx(_organizationId)
    {
        _mint(_msgSender(), _id, _amount, "");
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(AccessControlFacet, ERC1155Facet)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    )
        public
        virtual
        override
    {
        super.safeTransferFrom(_from, _to, _id, _amount, _data);
    }
}

contract MetaTxFacetTest is TestBase, DiamondManager, ERC1155HolderUpgradeable {
    using DiamondUtils for Diamond;
    using AddressUpgradeable for address;

    MetaTxImpl internal meta;

    function setUp() public {
        meta = new MetaTxImpl();
        meta.initialize(address(delegateApprover));
    }

    /**
     * @dev This test will have the 'from' account equal the account that signs the tx.
     *  This is to prove that transaction signing authority is working.
     */
    function testMetaTransactionSignerIsSender() public {
        meta.grantRole(ADMIN_ROLE, signingAuthority);

        // Call an admin function on behalf of the admin to prove that AccessControl can be called
        signAndExecuteMetaTx(
            ForwardRequest({
                from: signingAuthority,
                nonce: 1,
                organizationId: org2,
                data: abi.encodeWithSelector(MetaTxImpl.adminMint.selector, 1, 1)
            }),
            address(meta)
        );

        assertEq(meta.balanceOf(signingAuthority, 1), 1);

        // Set 1155 approval through meta tx to prove that any erc1155 function can be called
        signAndExecuteMetaTx(
            ForwardRequest({
                from: signingAuthority,
                nonce: 2,
                organizationId: org2,
                data: abi.encodeWithSignature("setApprovalForAll(address,bool)", alice, true)
            }),
            address(meta)
        );

        assertEq(meta.isApprovedForAll(signingAuthority, alice), true);
    }

    /**
     * @dev This test will have the 'from' account differ from the account that signs the tx.
     *  This is to prove that delegation is working.
     */
    function testMetaTransactionSignerIsDelegate() public {
        delegateApprover.setDelegateApprovalForSystem(org2, signingAuthority, true);

        // Call an admin function on behalf of the admin to prove that AccessControl can be called
        signAndExecuteMetaTx(
            ForwardRequest({
                from: deployer,
                nonce: 0,
                organizationId: org2,
                data: abi.encodeWithSelector(MetaTxImpl.adminMint.selector, 1, 1)
            }),
            address(meta)
        );

        assertEq(meta.balanceOf(deployer, 1), 1);

        // Set 1155 approval through meta tx to prove that any erc1155 function can be called
        signAndExecuteMetaTx(
            ForwardRequest({
                from: deployer,
                nonce: 2,
                organizationId: org2,
                data: abi.encodeWithSignature("setApprovalForAll(address,bool)", alice, true)
            }),
            address(meta)
        );

        assertEq(meta.isApprovedForAll(deployer, alice), true);
    }

    function testRevertOrganizationIdMismatch() public {
        meta.grantRole(ADMIN_ROLE, signingAuthority);

        vm.expectRevert(err(MetaTxFacetStorage.SessionOrganizationIdMismatch.selector, org2, org1));
        signAndExecuteMetaTx(
            ForwardRequest({
                from: signingAuthority,
                nonce: 0,
                organizationId: org2,
                data: abi.encodeWithSelector(MetaTxImpl.adminMintForOrg.selector, org1, 1, 1)
            }),
            address(meta)
        );
    }

    function testRevertInvalidSigner() public {
        vm.expectRevert(err(MetaTxFacetStorage.UnauthorizedSignerForSender.selector, signingAuthority, deployer));
        signAndExecuteMetaTx(
            ForwardRequest({
                from: deployer,
                nonce: 0,
                organizationId: org2,
                data: abi.encodeWithSelector(MetaTxImpl.adminMint.selector, 1, 1)
            }),
            address(meta)
        );
    }

    function testRevertInvalidNonce() public {
        meta.grantRole(ADMIN_ROLE, signingAuthority);
        signAndExecuteMetaTx(
            ForwardRequest({
                from: signingAuthority,
                nonce: 0,
                organizationId: org2,
                data: abi.encodeWithSelector(MetaTxImpl.adminMint.selector, 1, 1)
            }),
            address(meta)
        );

        vm.expectRevert(err(MetaTxFacetStorage.NonceAlreadyUsedForSender.selector, signingAuthority, 0));
        signAndExecuteMetaTx(
            ForwardRequest({
                from: signingAuthority,
                nonce: 0,
                organizationId: org2,
                data: abi.encodeWithSelector(MetaTxImpl.adminMint.selector, 1, 1)
            }),
            address(meta)
        );
    }

    function testRevertNonAdminSender() public {
        vm.expectRevert(errMissingRole("ADMIN", signingAuthority));
        signAndExecuteMetaTx(
            ForwardRequest({
                from: signingAuthority,
                nonce: 0,
                organizationId: org2,
                data: abi.encodeWithSelector(MetaTxImpl.adminMint.selector, 1, 1)
            }),
            address(meta)
        );
    }

    function testRevertNonApproved1155Sender() public {
        meta.grantRole(ADMIN_ROLE, signingAuthority);
        signAndExecuteMetaTx(
            ForwardRequest({
                from: signingAuthority,
                nonce: 0,
                organizationId: org2,
                data: abi.encodeWithSelector(MetaTxImpl.adminMint.selector, 1, 1)
            }),
            address(meta)
        );

        delegateApprover.setDelegateApprovalForSystem(org2, signingAuthority, true);

        vm.expectRevert("ERC1155: caller is not token owner or approved");
        signAndExecuteMetaTx(
            ForwardRequest({
                from: deployer,
                nonce: 1,
                organizationId: org2,
                data: abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256,uint256,bytes)", signingAuthority, alice, 1, 1, ""
                    )
            }),
            address(meta)
        );
    }
}

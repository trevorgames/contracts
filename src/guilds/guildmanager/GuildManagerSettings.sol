//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ADMIN_ROLE } from "src/libraries/LibAccessControlRoles.sol";

import { GuildCreationRule, MaxUsersPerGuildRule, GuildOrganizationInfo } from "src/interfaces/IGuildManager.sol";
import { IGuildToken } from "src/interfaces/IGuildToken.sol";
import { GuildManagerContracts, LibGuildManager, IGuildManager } from "./GuildManagerContracts.sol";
import { LibOrganizationManager } from "src/libraries/LibOrganizationManager.sol";
import { LibMeta } from "src/libraries/LibMeta.sol";

abstract contract GuildManagerSettings is GuildManagerContracts {
    function __GuildManagerSettings_init() internal onlyFacetInitializing {
        GuildManagerContracts.__GuildManagerContracts_init();
    }

    /**
     * @inheritdoc IGuildManager
     */
    function initializeForOrganization(
        bytes32 _organizationId,
        uint8 _maxGuildsPerUser,
        uint32 _timeoutAfterLeavingGuild,
        GuildCreationRule _guildCreationRule,
        MaxUsersPerGuildRule _maxUsersPerGuildRule,
        uint32 _maxUsersPerGuildConstant,
        address _customGuildManagerAddress,
        bool _requireTrevorTagForGuilds
    )
        external
        contractsAreSet
        whenNotPaused
        supportsMetaTx(_organizationId)
    {
        LibOrganizationManager.requireOrganizationValid(_organizationId);
        LibOrganizationManager.requireOrganizationAdmin(LibMeta._msgSender(), _organizationId);

        LibGuildManager.initializeForOrganization(_organizationId);

        LibGuildManager.setMaxGuildsPerUser(_organizationId, _maxGuildsPerUser);
        LibGuildManager.setTimeoutAfterLeavingGuild(_organizationId, _timeoutAfterLeavingGuild);
        LibGuildManager.setGuildCreationRule(_organizationId, _guildCreationRule);
        LibGuildManager.setMaxUsersPerGuild(_organizationId, _maxUsersPerGuildRule, _maxUsersPerGuildConstant);
        LibGuildManager.setCustomGuildManagerAddress(_organizationId, _customGuildManagerAddress);
        LibGuildManager.setRequireTrevorTagForGuilds(_organizationId, _requireTrevorTagForGuilds);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function setMaxGuildsPerUser(
        bytes32 _organizationId,
        uint8 _maxGuildsPerUser
    )
        external
        onlyRole(ADMIN_ROLE)
        contractsAreSet
        whenNotPaused
        supportsMetaTx(_organizationId)
    {
        LibOrganizationManager.requireOrganizationValid(_organizationId);
        LibOrganizationManager.requireOrganizationAdmin(LibMeta._msgSender(), _organizationId);

        LibGuildManager.setMaxGuildsPerUser(_organizationId, _maxGuildsPerUser);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function setTimeoutAfterLeavingGuild(
        bytes32 _organizationId,
        uint32 _timeoutAfterLeavingGuild
    )
        external
        onlyRole(ADMIN_ROLE)
        contractsAreSet
        whenNotPaused
        supportsMetaTx(_organizationId)
    {
        LibOrganizationManager.requireOrganizationValid(_organizationId);
        LibOrganizationManager.requireOrganizationAdmin(LibMeta._msgSender(), _organizationId);

        LibGuildManager.setTimeoutAfterLeavingGuild(_organizationId, _timeoutAfterLeavingGuild);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function setGuildCreationRule(
        bytes32 _organizationId,
        GuildCreationRule _guildCreationRule
    )
        external
        onlyRole(ADMIN_ROLE)
        contractsAreSet
        whenNotPaused
        supportsMetaTx(_organizationId)
    {
        LibOrganizationManager.requireOrganizationValid(_organizationId);
        LibOrganizationManager.requireOrganizationAdmin(LibMeta._msgSender(), _organizationId);

        LibGuildManager.setGuildCreationRule(_organizationId, _guildCreationRule);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function setMaxUsersPerGuild(
        bytes32 _organizationId,
        MaxUsersPerGuildRule _maxUsersPerGuildRule,
        uint32 _maxUsersPerGuildConstant
    )
        external
        onlyRole(ADMIN_ROLE)
        contractsAreSet
        whenNotPaused
        supportsMetaTx(_organizationId)
    {
        LibOrganizationManager.requireOrganizationValid(_organizationId);
        LibOrganizationManager.requireOrganizationAdmin(LibMeta._msgSender(), _organizationId);

        LibGuildManager.setMaxUsersPerGuild(_organizationId, _maxUsersPerGuildRule, _maxUsersPerGuildConstant);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function setRequireTrevorTagForGuilds(
        bytes32 _organizationId,
        bool _requireTrevorTagForGuilds
    )
        external
        onlyRole(ADMIN_ROLE)
        contractsAreSet
        whenNotPaused
        supportsMetaTx(_organizationId)
    {
        LibOrganizationManager.requireOrganizationValid(_organizationId);
        LibOrganizationManager.requireOrganizationAdmin(LibMeta._msgSender(), _organizationId);

        LibGuildManager.setRequireTrevorTagForGuilds(_organizationId, _requireTrevorTagForGuilds);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function setCustomGuildManagerAddress(
        bytes32 _organizationId,
        address _customGuildManagerAddress
    )
        external
        onlyRole(ADMIN_ROLE)
        contractsAreSet
        whenNotPaused
        supportsMetaTx(_organizationId)
    {
        LibOrganizationManager.requireOrganizationValid(_organizationId);
        LibOrganizationManager.requireOrganizationAdmin(LibMeta._msgSender(), _organizationId);

        LibGuildManager.setCustomGuildManagerAddress(_organizationId, _customGuildManagerAddress);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function setTrevorTagNFTAddress(address _trevorTagNFTAddress) external onlyRole(ADMIN_ROLE) {
        LibGuildManager.setTrevorTagNFTAddress(_trevorTagNFTAddress);
    }

    // =============================================================
    //                        VIEW FUNCTIONS
    // =============================================================

    /**
     * @inheritdoc IGuildManager
     */
    function getGuildOrganizationInfo(bytes32 _organizationId) external view returns (GuildOrganizationInfo memory) {
        return LibGuildManager.getGuildOrganizationInfo(_organizationId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

struct OrganizationInfo {
    // Slot 1
    string name;
    // Slot 2
    string description;
    // Slot 3 (160/256)
    address admin;
}

interface IOrganizationManager {
    /**
     * @notice Creates a new organization. For now, this can only be done by admins on the GuildManager contract.
     * @param _newOrganizationId The ID of the new organization
     * @param _name The name of the new organization
     * @param _description The description of the new organization
     */
    function createOrganization(
        bytes32 _newOrganizationId,
        string calldata _name,
        string calldata _description
    )
        external;

    /**
     * @dev Sets the name and description for an organization.
     * @param _organizationId The organization to set the name and description for.
     * @param _name The new name of the organization.
     * @param _description The new description of the organization.
     */
    function setOrganizationNameAndDescription(
        bytes32 _organizationId,
        string calldata _name,
        string calldata _description
    )
        external;

    /**
     * @dev Sets the admin for an organization.
     * @param _organizationId The organization to set the admin for.
     * @param _admin The new admin of the organization.
     */
    function setOrganizationAdmin(bytes32 _organizationId, address _admin) external;

    /**
     * @dev Retrieves the stored info for a given organization. Used to wrap the tuple from
     * calling the mapping directly from external contracts.
     * @param _organizationId The organization to return info for.
     */
    function getOrganizationInfo(bytes32 _organizationId) external view returns (OrganizationInfo memory);
}

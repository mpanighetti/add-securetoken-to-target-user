# Add SecureToken to Target User

This script adds a SecureToken to the target local user to prepare the Mac for enabling FileVault. Prompts for password of SecureToken admin (gets SecureToken Admin Username from Jamf Pro script parameter) and target user.

This workflow is required to authorize programmatically-created user accounts (that were not already explicitly given a SecureToken) to enable or use FileVault and unlock disk encryption on APFS-formatted startup volumes.

## Extension Attribute

**SecureToken Status - Logged-In User** is a Jamf Pro extension attribute (see [Computer Extension Attributes](Computer Extension Attributes) in Jamf Pro Documentation). After uploading this extension attribute to Jamf Pro, you can target a policy running this repository's main script at a smart computer group of Macs where the logged-in user has a value of `DISABLED` for this script's output. Once a SecureToken has been added to the target user, this script should report `ENABLED` if everything ran as expected.

## Credits

- `sysadminctl` SecureToken syntax discovered and formalized in [MacAdmins Slack](https://macadmins.slack.com) #filevault.

## License

This project is offered under an MIT License.

#!/bin/sh

###
#
#            Name:  Add SecureToken to Target User.sh
#     Description:  This script adds a SecureToken to the target local user to prepare the Mac for enabling FileVault. Prompts for password of SecureToken admin (gets SecureToken Admin Username from Jamf Pro script parameter) and target user. This workflow is required to authorize programmatically-created user accounts (that were not already explicitly given a SecureToken) to enable or use FileVault and unlock disk encryption on APFS-formatted startup volumes.
#                   https://github.com/mpanighetti/add-securetoken-to-target-user
#
#                   MIT License
#
#                   Copyright (c) 2017 Mario Panighetti
#
#                   Permission is hereby granted, free of charge, to any person obtaining a copy
#                   of this software and associated documentation files (the "Software"), to deal
#                   in the Software without restriction, including without limitation the rights
#                   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#                   copies of the Software, and to permit persons to whom the Software is
#                   furnished to do so, subject to the following conditions:
#
#                   The above copyright notice and this permission notice shall be included in all
#                   copies or substantial portions of the Software.
#
#                   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#                   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#                   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#                   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#                   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#                   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#                   SOFTWARE.
#
#          Author:  Mario Panighetti
#         Created:  2017-10-04
#   Last Modified:  2025-04-28
#         Version:  4.1
#
###



########## variable-ing ##########



# Jamf Pro script parameter: "SecureToken Admin Username"
# A local administrator account with SecureToken access.
secureTokenAdmin="${4}"
# Jamf Pro script parameter: "Target Username"
# (optional) A local user account requiring SecureToken. If undefined, script will default to the logged-in user as the target.
targetUsername="${5}"
macOSVersionMajor=$(/usr/bin/sw_vers -productVersion | /usr/bin/awk -F . '{print $1}')
macOSVersionMinor=$(/usr/bin/sw_vers -productVersion | /usr/bin/awk -F . '{print $2}')
macOSVersionBuild=$(/usr/bin/sw_vers -productVersion | /usr/bin/awk -F . '{print $3}')
# Need default password values so the initial logic loops will properly fail when validating passwords. You can store the actual credentials here to skip password prompts entirely, but for security reasons this is not generally recommended. Please don't actually use "foo" as a password, for so many reasons.
secureTokenAdminPass="foo"
targetUserPassword="foo"
passwordPrompt="foo"



########## function-ing ##########



# Exits with error if any required Jamf Pro arguments are undefined.
check_jamf_pro_arguments () {

  if [ -z "$secureTokenAdmin" ]; then
    echo "❌ ERROR: Undefined Jamf Pro argument, unable to proceed."
    exit 74
  fi
  
}


# Exits if macOS version predates the use of SecureToken functionality.
check_macos_version () {

  # Exit if macOS < 10.
  if [ "$macOSVersionMajor" -lt 10 ]; then
    echo "macOS version ${macOSVersionMajor} predates the use of SecureToken functionality, no action required."
    exit 0
  # Exit if macOS 10 < 10.13.4.
  elif [ "$macOSVersionMajor" -eq 10 ]; then
    if [ "$macOSVersionMinor" -lt 13 ]; then
      echo "macOS version ${macOSVersionMajor}.${macOSVersionMinor} predates the use of SecureToken functionality, no action required."
      exit 0
    elif [ "$macOSVersionMinor" -eq 13 ] && [ "$macOSVersionBuild" -lt 4 ]; then
      echo "macOS version ${macOSVersionMajor}.${macOSVersionMinor}.${macOSVersionBuild} predates the use of SecureToken functionality, no action required."
      exit 0
    fi
  fi
  
}


# Sets target username to defined value from script parameter, or defaults to logged-in user if undefined.
check_target_username () {

  if [ -z "$targetUsername" ]; then
    echo "Target Username undefined. Defaulting to logged-in user..."
    loggedInUser=$(/usr/bin/stat -f%Su "/dev/console")
    # Exit if root is the current logged-in user, or no logged-in user is detected.
    if [ "$loggedInUser" = "root" ] || [ -z "$loggedInUser" ]; then
      echo "Nobody is logged in."
      exit 0
    else
      targetUsername="$loggedInUser"
    fi
  fi
  echo "Target Username: ${targetUsername}"

}


# Exits if target user already has SecureToken.
check_securetoken_target_user () {

  if /usr/sbin/sysadminctl -secureTokenStatus "$targetUsername" 2>&1 | /usr/bin/grep -q "ENABLED"; then
    echo "${targetUsername} already has a SecureToken. No action required."
    exit 0
  fi
  
}


# Exits with error if $secureTokenAdmin does not have SecureToken (unless running macOS 10.15 or later, in which case exit with explanation).
check_securetoken_admin () {

  if /usr/sbin/sysadminctl -secureTokenStatus "$secureTokenAdmin" 2>&1 | /usr/bin/grep -q "DISABLED" ; then
    if [ "$macOSVersionMajor" -gt 10 ] || [ "$macOSVersionMajor" -eq 10 ] && [ "$macOSVersionMinor" -gt 14 ]; then
      echo "⚠️ Neither ${secureTokenAdmin} nor ${targetUsername} has a SecureToken, but in macOS 10.15 or later, a SecureToken is automatically granted to the first user to enable FileVault (if no other users have SecureToken), so this may not be necessary. Try enabling FileVault for ${targetUsername}. If that fails, see what other user on the system has SecureToken, and use its credentials to grant SecureToken to ${targetUsername}."
      exit 0
    else
      echo "❌ ERROR: ${secureTokenAdmin} does not have a valid SecureToken, unable to proceed. Please update Jamf Pro policy to target another admin user with SecureToken."
      exit 1
    fi
  else
    echo "✅ Verified ${secureTokenAdmin} has SecureToken."
  fi
  
}


# Prompts for local password.
local_account_password_prompt () {

  passwordPrompt=$(/usr/bin/osascript -e "set user_password to text returned of (display dialog \"${2}\" default answer \"\" with hidden answer)")
  if [ -z "$passwordPrompt" ]; then
    echo "❌ ERROR: A password was not entered for ${1}, unable to proceed. Please rerun policy; if issue persists, a manual SecureToken add will be required to continue."
    exit 1
  fi
  
}


# Validates provided password.
local_account_password_validation () {

  if /usr/bin/dscl "/Local/Default" authonly "${1}" "${2}" > "/dev/null" 2>&1; then
    echo "✅ Password successfully validated for ${1}."
  else
    echo "❌ ERROR: Failed password validation for ${1}. Please reenter the password when prompted."
  fi
  
}


# Adds SecureToken to target user.
securetoken_add () {

  /usr/sbin/sysadminctl \
    -adminUser "${1}" \
    -adminPassword "${2}" \
    -secureTokenOn "${3}" \
    -password "${4}"

  # Verify successful SecureToken add.
  secureTokenCheck=$(/usr/sbin/sysadminctl -secureTokenStatus "${3}" 2>&1)
  if echo "$secureTokenCheck" | /usr/bin/grep -q "DISABLED"; then
    echo "❌ ERROR: Failed to add SecureToken to ${3}. Please rerun policy; if issue persists, a manual SecureToken add will be required to continue."
    exit 126
  elif echo "$secureTokenCheck" | /usr/bin/grep -q "ENABLED"; then
    echo "Successfully added SecureToken to ${3}."
  else
    echo "❌ ERROR: Unexpected result, unable to proceed. Please rerun policy; if issue persists, a manual SecureToken add will be required to continue."
    exit 1
  fi
  
}



########## main process ##########



# Check script prerequisites.
check_jamf_pro_arguments
check_macos_version
check_target_username
check_securetoken_target_user
check_securetoken_admin


# Add SecureToken to target user.
until /usr/sbin/sysadminctl -secureTokenStatus "$targetUsername" 2>&1 | /usr/bin/grep -q "ENABLED"; do

  # Get $secureTokenAdmin password.
  echo "${targetUsername} missing SecureToken, prompting for credentials..."
  until /usr/bin/dscl "/Local/Default" authonly "$secureTokenAdmin" "$secureTokenAdminPass" > "/dev/null" 2>&1; do
    local_account_password_prompt "$secureTokenAdmin" "Please enter password for ${secureTokenAdmin}. User's credentials are needed to grant a SecureToken to ${targetUsername}."
    secureTokenAdminPass="$passwordPrompt"
    local_account_password_validation "$secureTokenAdmin" "$secureTokenAdminPass"
  done

  # Get target user's password.
  until /usr/bin/dscl "/Local/Default" authonly "$targetUsername" "$targetUserPassword" > "/dev/null" 2>&1; do
    local_account_password_prompt "$targetUsername" "Please enter password for ${targetUsername} to add SecureToken."
    targetUserPassword="$passwordPrompt"
    local_account_password_validation "$targetUsername" "$targetUserPassword"
  done

  # Add SecureToken using provided credentials.
  securetoken_add "$secureTokenAdmin" "$secureTokenAdminPass" "$targetUsername" "$targetUserPassword"

done


# Echo successful result.
echo "✅ Verified SecureToken is enabled for ${targetUsername}."



exit 0

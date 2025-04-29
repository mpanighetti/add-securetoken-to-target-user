#!/bin/sh

###
#
#            Name:  SecureToken Status - Logged-In User.sh
#     Description:  Reports whether SecureToken is enabled for the currently logged-in user.
#                   https://github.com/mpanighetti/add-securetoken-to-logged-in-user
#          Author:  Mario Panighetti
#         Created:  2022-02-08
#   Last Modified:  2025-04-28
#         Version:  1.0.2
#
###



########## variable-ing ##########



loggedInUser=$(/usr/bin/stat -f%Su "/dev/console")



########## main process ##########



# Check SecureToken for currently logged-in user and report results.
echo "<result>$(/usr/sbin/sysadminctl -secureTokenStatus "$loggedInUser" 2>&1 | /usr/bin/awk '{print $7}')</result>"



exit 0

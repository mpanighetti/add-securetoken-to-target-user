#!/bin/sh

###
#
#            Name:  SecureToken Status - Logged-In User.sh
#     Description:  Reports whether SecureToken is enabled for the currently logged-in user.
#                   https://github.com/mpanighetti/add-securetoken-to-logged-in-user
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

#!/bin/bash

#
# Quick and dirty tool for testing if hosts respond
# - checks a sample set of hostnames we want to check for response
# - performs a simple ping, with a more than reasonable wait time for response 
#

# define sample set of hostnames to check
HOSTNAMES=(
yahoo.com
google.com
bing.com
)


# loop through hosts pinging each and reporting result
for H in ${HOSTNAMES[@]};do
        ping -W2 -c1 $H  > /dev/null 2>&1 && echo -e "\033[34m[PASS]\033[0m $H" || echo -e "\033[34m[FAIL]\033[0m $H"
done



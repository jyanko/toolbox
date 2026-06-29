#!/bin/bash
#
# Script to quickly create MR information line
# - useful for creating slugline for use in notes or posting to chat channels for review/status
# - expects to be run from within a clone of the repo containing the specified MR number
#
# Formats a string like follows...
#    **<state>**:   MR-<mrNumber> (<namespace>/<repo>) - <title> / <branch>
#
# Samples:
#    **MERGED**: MR-123 (jyanko/toolbox) - TB-1 - new functions getBurgers() and getBeer() / TB-1-add_lunch_functions
#      **OPEN**: MR-123 (jyanko/toolbox) - TB-2 - add breakpoints log entries / TB-2-log_breakpoints
#
# Dependencies
#
#   - glab (GitLab command line util: https://gitlab.com/gitlab-org/cli)
#   - jq (jq bash JSON parser util: https://stedolan.github.io/jq/)
#
# Usage:
#
#    gmrSlug.sh <mr_number> [remote]
#
#    remote defaults to 'origin' if not specified
#
#    EXAMPLES:
#
#        gmrSlug.sh 131              # uses origin (your fork)
#        gmrSlug.sh 131 upstream     # uses upstream (the source repo)
#

if [ -z "$1" ]; then
    echo "ERROR: this script requires an MR number as input param (uses the 'glab' cmdline util to capture MR info)"
    echo
    echo "    EXAMPLES:"
    echo
    echo "        $(basename $0) 131              # query MR against origin (your fork)"
    echo "        $(basename $0) 131 upstream     # query MR against upstream repo"
    echo
    exit 1
fi

MR_NUMBER=$1
REMOTE=${2:-origin}

# Validate that the specified remote actually exists
if ! git remote | grep -q "^${REMOTE}$"; then
    echo "ERROR: remote '${REMOTE}' not found in this repo."
    echo
    echo "Available remotes:"
    git remote -v | grep fetch | awk '{print "    " $1 " -> " $2}'
    echo
    exit 1
fi

MR_REPO=$(git remote -v | grep "^${REMOTE}" | grep fetch | sed -e 's/\.git.*//' | awk -F ':' '{print $2}')

# glab needs to know which repo to query when not using origin;
# pass the repo path explicitly so it hits the right project
MR_JSON=$(glab mr view ${MR_NUMBER} --repo "${MR_REPO}" --output json)
MR_TITLE=$(echo $MR_JSON | jq -r .title)
MR_BRANCH=$(echo $MR_JSON | jq -r .source_branch)
MR_STATE=$(echo $MR_JSON | jq -r .state | tr '[:lower:]' '[:upper:]' | sed 's/OPENED/OPEN/')
MR_URL=$(echo $MR_JSON | jq -r .web_url)
#MR_FILED="${MR_STATE}: MR-${MR_NUMBER} (${MR_REPO}) - ${MR_TITLE} / ${MR_BRANCH} \n* $MR_URL"
MR_FILED="${MR_STATE}: Merge Request: ${MR_NUMBER} (${MR_REPO}) - ${MR_TITLE} \n- branch: ${MR_BRANCH} \n- link: $MR_URL"

printf "$MR_FILED \n"
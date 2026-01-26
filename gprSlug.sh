#!/bin/bash
#
# Script to quickly create PR information line
# - useful for creating slugline for use in notes or posting to chat channels for review/status
# - expects to be run from within a clone of the repo containing the specified PR number
#
# Formats a string like follows...
#    **<state>**:   <prNumber> (<org>/<repo>) - <title> / <branch>
#
# Samples:
#    **MERGED**: PR-123 (jyanko/toolbox) - TB-1 - new functions getBurgers() and getBeer() / TB-1-add_lunch_functions
#      **OPEN**: PR-123 (jyanko/toolbox) - TB-2 - add breakpoints log entries / TB-2-log_breakpoints
#
# Dependencies
#
# 	- gh (github command line util: https://cli.github.com)
#   - jq (jq bash JSON parser util: https://stedolan.github.io/jq/)
#
# Usage:
#
#    gprSlug.sh 131
#
#

if [ -z $1 ]; then
	echo "ERROR: this script requires a PR number as input param (uses the 'gh' cmdline util to capture PR info)"
	echo
	echo "    EXAMPLE:"
	echo
	echo "        $(basename $0) 131"
	echo
	exit 1
fi

PR_NUMBER=$1
PR_REPO=$(git remote -v | grep origin | sed -e 's/\.git.*//' | awk -F ':' '{print $2}' | uniq )
PR_JSON=$(gh pr view ${PR_NUMBER} --json number,title,state,reviewDecision,headRefName,baseRefName,state,url)
PR_TITLE=$(echo $PR_JSON | jq -r .title)
PR_BRANCH=$(echo $PR_JSON | jq -r .headRefName)
PR_STATE=$(echo $PR_JSON | jq -r .state)
PR_URL=$(echo $PR_JSON | jq -r .url)
PR_FILED="\033[34m${PR_STATE}:\033[0m PR-${PR_NUMBER} (${PR_REPO}) - ${PR_TITLE} / ${PR_BRANCH} \n* $PR_URL"

printf "$PR_FILED \n"

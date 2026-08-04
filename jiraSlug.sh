#!/bin/bash
#
# Script to quickly create Jira ticket information line
# - useful for creating slugline for use in notes or posting to chat channels for review/status
#
# Formats a string like follows...
#    <TICKET-KEY> - <summary>
#
# Samples:
#    PROJ-1234 - Sample Ticket Summary
#
# Dependencies
#
#   - curl
#   - jq (jq bash JSON parser util: https://stedolan.github.io/jq/)
#
# Auth
#
#   - requires JIRA_BASE_URL and JIRA_PAT env vars (Jira Data Center
#     Personal Access Token, sent as a Bearer token per
#     https://confluence.atlassian.com/jirakb/using-personal-access-tokens-1115696409.html)
#
# Usage:
#
#    jiraSlug.sh <ticket_key>
#
#    EXAMPLES:
#
#        jiraSlug.sh PROJ-1234
#

if [ -z "$1" ]; then
    echo "ERROR: this script requires a Jira ticket key as input param (uses the Jira REST API to capture ticket info)"
    echo
    echo "    EXAMPLES:"
    echo
    echo "        $(basename $0) PROJ-1234"
    echo
    exit 1
fi

if [ -z "$JIRA_BASE_URL" ] || [ -z "$JIRA_PAT" ]; then
    echo "ERROR: JIRA_BASE_URL and JIRA_PAT env vars must both be set."
    echo
    echo "    Create a Personal Access Token in Jira: Profile -> Personal Access Tokens"
    echo
    exit 1
fi

TICKET_KEY=$1

TICKET_JSON=$(curl -s -H "Authorization: Bearer ${JIRA_PAT}" \
    -H "Accept: application/json" \
    "${JIRA_BASE_URL}/rest/api/2/issue/${TICKET_KEY}?fields=summary")

TICKET_ERROR=$(echo "$TICKET_JSON" | jq -r '.errorMessages // empty')
if [ -n "$TICKET_ERROR" ]; then
    echo "ERROR: $TICKET_ERROR"
    exit 1
fi

TICKET_SUMMARY=$(echo "$TICKET_JSON" | jq -r '.fields.summary // empty')
if [ -z "$TICKET_SUMMARY" ]; then
    echo "ERROR: could not find ticket '${TICKET_KEY}' or read its summary."
    exit 1
fi

TICKET_SLUG="${TICKET_KEY} - ${TICKET_SUMMARY}"

printf "%s\n" "$TICKET_SLUG"

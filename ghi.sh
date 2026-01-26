#!/bin/bash

# GitHub Issues Viewer (ghi.sh)
#
# A utility script to view GitHub issues filtered by project status.
# Displays issues in a formatted table with ID, title, status, labels, and last updated time.
#
# Usage:
#   ./ghi.sh [command]
#
# Commands:
#   open     - Show all open issues (sorted by status, reverse alphabetical)
#   todo     - Show issues in "To-Do" status
#   back     - Show issues in "Backlog" status
#   wip      - Show issues "In progress" or "In review"
#   (none)   - Show all categories
#
# Requires: gh (GitHub CLI) and jq
#
# Useful alias to add to your shell profile for using this script
#
#   alias ghi='ghi.sh'         # allow passing params(back|todo|wip|open) on cmdline ie; `ghi wip`
#   alias ghback='ghi.sh back' 
#   alias ghtodo='ghi.sh todo'
#   alias ghwip='ghi.sh wip'
#   alias ghopen='ghi.sh open'


function ghwip() {
  # ghwip:
  #   - command shows all issues that are "In progress" or "In review" in a nice table format
  #   - similar to the standard gh issue list output but filtered to your active work
  #
  gh issue list --json number,title,labels,updatedAt,projectItems | \
    jq -r '["\033[34mID\033[0m", "\033[34mTITLE\033[0m", "\033[34mSTATUS\033[0m", "\033[34mLABELS\033[0m", "\033[34mUPDATED\033[0m"], (.[] | . as $issue | (.projectItems[] | select(.status.name == "In progress" or .status.name == "In review")) as $project | [("#" + ($issue.number | tostring)), $issue.title, $project.status.name, (if ($issue.labels | length) > 0 then ($issue.labels | map(.name) | join(", ")) else "---" end), ($issue.updatedAt | fromdateiso8601 | now - . | if . < 86400 then (. / 3600 | floor | tostring) + " hours ago" else (. / 86400 | floor | tostring) + " days ago" end)]) | @tsv' | \
    column -t -s $'\t'
}

function ghtodo() {
  # ghtodo:
  #   - command shows all issues that are in "To-Do" status
  #   - similar to the standard gh issue list output but filtered to todo items
  #
  gh issue list --json number,title,labels,updatedAt,projectItems | \
    jq -r '["\033[34mID\033[0m", "\033[34mTITLE\033[0m", "\033[34mSTATUS\033[0m", "\033[34mLABELS\033[0m", "\033[34mUPDATED\033[0m"], (.[] | . as $issue | (.projectItems[] | select(.status.name == "To-Do")) as $project | [("#" + ($issue.number | tostring)), $issue.title, $project.status.name, (if ($issue.labels | length) > 0 then ($issue.labels | map(.name) | join(", ")) else "---" end), ($issue.updatedAt | fromdateiso8601 | now - . | if . < 86400 then (. / 3600 | floor | tostring) + " hours ago" else (. / 86400 | floor | tostring) + " days ago" end)]) | @tsv' | \
    column -t -s $'\t'
}

function ghback() {
  # ghtodo:
  #   - command shows all issues that are in "Backlog" status
  #   - similar to the standard gh issue list output but filtered to todo items
  #
  gh issue list --json number,title,labels,updatedAt,projectItems | \
    jq -r '["\033[34mID\033[0m", "\033[34mTITLE\033[0m", "\033[34mSTATUS\033[0m", "\033[34mLABELS\033[0m", "\033[34mUPDATED\033[0m"], (.[] | . as $issue | (.projectItems[] | select(.status.name == "Backlog")) as $project | [("#" + ($issue.number | tostring)), $issue.title, $project.status.name, (if ($issue.labels | length) > 0 then ($issue.labels | map(.name) | join(", ")) else "---" end), ($issue.updatedAt | fromdateiso8601 | now - . | if . < 86400 then (. / 3600 | floor | tostring) + " hours ago" else (. / 86400 | floor | tostring) + " days ago" end)]) | @tsv' | \
    column -t -s $'\t'
}

function ghopen() {
  # ghopen:
  #   - command shows all issues that are in "open" state (note: this is 'state' not 'status')
  #   - similar to the standard gh issue list output
  gh issue list --state open --json number,title,labels,updatedAt,projectItems | \
    jq -r '(["\033[34mID\033[0m", "\033[34mTITLE\033[0m", "\033[34mSTATUS\033[0m", "\033[34mLABELS\033[0m", "\033[34mUPDATED\033[0m"]), ([.[] | . as $issue | (if ($issue.projectItems | length) > 0 then ($issue.projectItems[0].status.name // "No Status") else "No Status" end) as $status | [("#" + ($issue.number | tostring)), $issue.title, $status, (if ($issue.labels | length) > 0 then ($issue.labels | map(.name) | join(", ")) else "---" end), ($issue.updatedAt | fromdateiso8601 | now - . | if . < 86400 then (. / 3600 | floor | tostring) + " hours ago" else (. / 86400 | floor | tostring) + " days ago" end)]] | sort_by(.[2]) | reverse[]) | @tsv' | \
    column -t -s $'\t'
}

function displayHelp {
    echo "Usage: $0 {open|todo|back|backlog|wip}"
    echo "  open     - Show all open issues"
    echo "  todo     - Show issues in To-Do status"
    echo "  back     - Show issues in Backlog status"
    echo "  wip      - Show issues in progress or in review"
    echo "  (none)   - Show all categories"
    exit 1
}

# Main script logic
case "${1:-}" in
  open)
    ghopen
    ;;
  todo)
    ghtodo
    ;;
  back|backlog)
    ghback
    ;;
  wip)
    ghwip
    ;;
  "")
    # If no argument provided, show all (original behavior)
    ghopen
    ;;
  *) displayHelp ;;
esac

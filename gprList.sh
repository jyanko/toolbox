#!/bin/bash

#############################################
# FUNCTIONS
#############################################

function displayHelp() {

    SCRIPT_NAME=$(basename $0)

    printf '%s' "
    ---------------------------------------------------------------
    $(basename $0)
    ---------------------------------------------------------------
    This script generates an adhoc report of merged PRs for a 
    defined repo between specified dates
    
    Syntax: 

        ${SCRIPT_NAME} [-h] -r <repo> -s <date_start> -e <date_end> 

    Input Params:
    
      -r <repo>       : (required) repo url to report on
      -s <date_start> : (required) start of date range to consider - format: YYYY-MM-DD
      -e <date_end>   : (required) end   of date range to consider - format: YYYY-MM-DD
      -h              : display script help
    
    Example: 

        ${SCRIPT_NAME} -r 'https://github.com/jyanko/toolbox' -s '2021-10-01' -e '2022-03-17'
       

    "
    exit
}

function prList() {
    #
    # generate a log of pull requests for a repo
    #
    # params:
    #
    #   @1 = <giturl>     # scm url w/o protocol (ie: github.com/jyanko/toolbox)
    #   @2 = <date_start> # start of date range to pull (ie: 2021-10-03)
    #   @3 = <date_end>   # end   of date range to pull (ie: 2022-10-31)
    #
    # example usage:
    #
    # prList "github.com/jyanko/toolbox"
    #
    #
    WORKING_DIR=${PWD}
    GIT_ROOT=$(echo $1 | awk -F '/' '{print $1}')
    GIT_PROJ=$(echo $1 | awk -F '/' '{print $2}')
    GIT_REPO=$(echo $1 | awk -F '/' '{print $3}')
    GIT_LOGFILE="${PWD}/${GIT_REPO}.mergelog.csv"
    GIT_DATE_START=$2
    GIT_DATE_END=$3

    if [ ! -d ${GIT_REPO} ]; then
        gh repo clone ${GIT_ROOT}/${GIT_PROJ}/${GIT_REPO} ${GIT_REPO}
    fi
    cd ${GIT_REPO}
    touch ${GIT_LOGFILE}
    echo '"number","title","author","merged"' >${GIT_LOGFILE}
    gh repo sync
    set -x
    gh pr list --state merged \
        --search "merged:${GIT_DATE_START}..${GIT_DATE_END}" \
        --limit 10000 \
        --json number,title,author,mergedAt |
        jq -r '.[] | [.number, .title, .author.login, .mergedAt] | @csv ' >>${GIT_LOGFILE}

    set +x

    head -5 ${GIT_LOGFILE}

    cd $WORKING_DIR

}

#############################################
# RUN STARTS HERE
#############################################
# Gather CLI Input
while getopts "hr:s:e:" arg; do
    case $arg in
    h) displayHelp ;;
    r) PARAM_REPO=$OPTARG ;;
    s) PARAM_DATE_START=$OPTARG ;;
    e) PARAM_DATE_END=$OPTARG ;;
    esac
done
shift $((OPTIND - 1))

test -z "$PARAM_REPO" && echo "No Repo provided" && displayHelp
test -z "$PARAM_DATE_START" && echo "No Start Date provided" && displayHelp
test -z "$PARAM_DATE_END" && echo "No End Date provided" && displayHelp

echo -e "\033[34mPARAM_REPO      :\033[0m $PARAM_REPO"
echo -e "\033[34mPARAM_DATE_START:\033[0m $PARAM_DATE_START"
echo -e "\033[34mPARAM_DATE_END  :\033[0m $PARAM_DATE_END"

DATE_START="$PARAM_DATE_START"
DATE_END="$PARAM_DATE_END"

# Define target repos to report on from input param
ARRAY_URLS=(
    $PARAM_REPO
)

for SCM_URL in ${ARRAY_URLS[*]}; do
    echo -e "\033[34m[PROCESSING]:\033[0m $SCM_URL"
    # strip protocol from URL (ie: https://)
    SCRUBBED_SCM_URL=$(echo $SCM_URL | perl -pe 's/^.*\:\/\///;')
    echo -e "\033[34m  [STRIPPED]:\033[0m $SCRUBBED_SCM_URL"
    prList "${SCRUBBED_SCM_URL}" "${DATE_START}" "${DATE_END}"
done

echo -e "\033[34mDir Contents...\033[0m"
ls -l

echo -e "\033[34mLine counts of log files...\033[0m"
wc -l *.csv

################################
#
# gStale - expose stale git branches
#

################################################
# CONFIG
################################################
DEBUG="false"       # debug may be enabled per run by passing -d flag on cmdline

################################################
# FUNCTIONS
################################################
function debugMessage() {
    if [ "$DEBUG" = "true" ];then
        echo "[DEBUG] $1" >&2
    fi
} 

function displayHelp() {
    printf "
    ---------------------------------------------------------------
    $(basename $0)
    ---------------------------------------------------------------
    Exposes stale git branches

    - requires two params
    - expects to run in checkout of master branch

    Syntax: 

        $(basename $0) <name> <merge_status>

    Input Params:
    
      @param1    : author name  (jim|bob|sam)
      @param2    : merge status (merged|no-merged) 
    
    Example: 
        $(basename $0)  jim merged     # report stale branches that have been merged to master
        $(basename $0)  jim no-merged  # report stale branches that have NOT been merged to master

    "
    exit 1
}

################################################
# RUN
################################################

myAuthor="$1"
myStatus="$2"
myCurrBranch=$(git rev-parse --abbrev-ref HEAD)
echo -e "\033[34m- Current Branch         :\033[0m $myCurrBranch"
echo -e "\033[34m- Find Stale Branches for:\033[0m $myAuthor"
echo -e "\033[34m- Reporting Merge Status :\033[0m $myStatus"

if [ $myCurrBranch != "master" ];then
    echo "Current Branch is: $myCurrBranch (script expects to be run from 'master' branch)"
    exit 1
fi

if [ $myCurrBranch != "master" ] || [ -z $1 ] || [ -z $2 ]; then
    echo "ERROR: Unexpected/Missing input"
    echo "	-> param1: $1"
    echo "	-> param2: $2"
    
    displayHelp
fi
echo -e "\033[34mCurrent Branch         :\033[0m $myCurrBranch"
echo -e "\033[34mFind Stale Branches for:\033[0m $myAuthor"
echo -e "\033[34mReporting Merge Status :\033[0m $myStatus"
for branch in $(git branch -r --${myStatus} | grep -v HEAD); do 
    echo $(git show --format="%ci %cr %an" $branch | head -n 1) \\t$branch; 
done | sort -r | grep -i $myAuthor


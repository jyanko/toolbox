################################
#
# gChange - list changes since last release
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

################################################
# RUN
################################################
# do prereqs check
PREREQS=( "gh" "git" )
for REQ in ${PREREQS[*]};do
    which $REQ  >/dev/null 2>&1 && REQ_STATUS="true" || REQ_STATUS="false"
    if [ "$REQ_STATUS" = "false" ];then
        echo "NOT FOUND: $REQ -- gChange requires $REQ installed.  Exitting now..."
        return 1
    fi
done

# verify we're on master branch
if [ "$(git branch --show)" != "master" ];then
    echo "gChange *MUST* run in checkout of 'master' branch - currently on: $(git branch --show)"
    exit 1
else
    echo "gChange: in 'master'"
fi

# update re
git fetch --all


LAST_TAG=$(gh release list | egrep '^[0-9\.]+\s+Latest\s+.*$'   | awk '{print $1}')
# LAST_DATE=`git show $LAST_TAG --pretty=format:"%ad" --date=iso-strict`
LAST_DATE=$(git show --date=iso-strict --format="DATE^%ad" $LAST_TAG | grep 'DATE^' | awk -F '^' '{print $2}')

PR_MERGED=$(gh pr list     --base master --search "state:closed review:approved merged:>${LAST_DATE}"         --json number,title,state,reviewDecision)
PR_MERGEREADY=$(gh pr list --base master --search "state:open     review:approved label:ready-for-merge"      --json number,title,state,reviewDecision)
PR_APPROVED=$(gh pr list   --base master --search "state:open     review:approved -label:ready-for-merge"     --json number,title,state,reviewDecision)
PR_PENDING=$(gh pr list    --base master --search "state:open     review:required -label:on-hold draft:false" --json number,title,state,reviewDecision)
PR_ONHOLD=$(gh pr list     --base master --search "state:open     label:on-hold draft:false"                  --json number,title,state,reviewDecision)
PR_DRAFT=$(gh pr list      --base master --search "state:open     review:required  draft:true"                --json number,title,state,reviewDecision)

PR_ALL=$(
    echo $PR_MERGED      | jq '.[] | "\(.number)   ^ \(.title) ^ \(.reviewDecision) ^ \(.state)"' 
    echo $PR_MERGEREADY  | jq '.[] | "\(.number)   ^ \(.title) ^ \(.reviewDecision) ^ \(.state) (READY-FOR-MERGE)"' 
    echo $PR_APPROVED    | jq '.[] | "\(.number)   ^ \(.title) ^ \(.reviewDecision) ^ \(.state)"' 
    echo $PR_PENDING     | jq '.[] | "\(.number)   ^ \(.title) ^ \(.reviewDecision) ^ \(.state)"' 
    echo $PR_ONHOLD      | jq '.[] | "\(.number)   ^ \(.title) ^ \(.reviewDecision) ^ \(.state) (ON-HOLD)"' 
    echo $PR_DRAFT       | jq '.[] | "\(.number)   ^ \(.title) ^ \(.reviewDecision) ^ \(.state) (DRAFT)"'   
)

echo -e "\033[34m-----------------------------------------------\033[0m" 
echo -e "\033[34mPull Requests since: v$LAST_TAG ($LAST_DATE)\033[0m"
echo -e "\033[34m-----------------------------------------------\033[0m"
printf "$PR_ALL \n" | tr -d '"' | sort -t "^" -k3,4 | column -ts '^'






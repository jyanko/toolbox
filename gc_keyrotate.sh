#!/bin/bash


function debugMessage() {
    if [ $DEBUG == "true" ];then
        echo "[DEBUG] $1"
    fi
}

function printBanner() {
    echo -e "\033[34m------------------------------------------------------------\033[0m"
    echo -e "\033[34m$1\033[0m"
    echo -e "\033[34m------------------------------------------------------------\033[0m"
    
}

function createNewKey {
	# define temp file for key creation
	KEY_TEMP=`mktemp ~/.config/gcloud/gckey.temp.XXXXXX`                

	debugMessage "KEY_TEMP            : ${KEY_TEMP}"

	# CREATE new key
	gcloud iam service-accounts keys create ${KEY_TEMP} --iam-account ${IAM_ACCT}

	KEY_ID=$(jq .private_key_id ${KEY_TEMP} | tr -d '"')                # get the key_id from the newly created key temp file contents
	KEY_ID_SHORT=$(echo ${KEY_ID} | cut -c 1-12)                        # set short key_id from the key id
	KEY_FILE_NEW=~/.config/gcloud/${IAM_PROJECT}-${KEY_ID_SHORT}.json   # set key file name like -> ltf-prd-e3a6-82bf3658b518.json

	debugMessage "KEY_ID              : ${KEY_ID}"
	debugMessage "KEY_ID_SHORT        : ${KEY_ID_SHORT}"
	debugMessage "KEY_FILE_NEW        : ${KEY_FILE_NEW}"

	# RENAME the new keyfile locally
	mv ${KEY_TEMP} ${KEY_FILE_NEW}
}

function deleteOldKey {
	# DELETE the old key
	gcloud iam service-accounts keys delete ${OLD_KEY_ID} --iam-account ${IAM_ACCT} --quiet

	# RENAME the old keyfile locally (mark as .deleted)
	for OLD_KEY_FILE in ${OLD_KEY_FILES_ARRAY[*]};do  
	    debugMessage "-> processing: ${OLD_KEY_FILE}"  
	    mv ${OLD_KEY_FILE} ${OLD_KEY_FILE}.deleted
	done
}

################################################################################################################
# START RUN
################################################################################################################

DEBUG="true"   # (true|false) enable debugMessage output

if [ -z $1 ] || [ -z $2 ] || [ -z $3 ];then
	
	printBanner "[ERROR] missing params"
	
	echo "requires params: iam_account, key_id, action (as seen in example commands here), enter a placholder string for key_id when using create mode"
	echo
	echo "        $(basename $0) '<user>@<project>.iam.gserviceaccount.com' 'b4fxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx78a8' rotate"
	echo "        $(basename $0) '<user>@<project>.iam.gserviceaccount.com' 'b4fxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx78a8' delete"
	echo "        $(basename $0) '<user>@<project>.iam.gserviceaccount.com' 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' create"  
	echo "        $(basename $0) '<user>@<project>.iam.gserviceaccount.com' 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' list" 
	echo
	exit 1
else
	IAM_ACCT=$1
	OLD_KEY_ID=$2
	KEY_ACTION=$3
fi	

IAM_USER=$(echo $IAM_ACCT | perl -pe 's/^(.*)(@.*)$/\1/')
IAM_PROJECT=$(echo $IAM_ACCT | perl -pe 's/^(.*@)([\w\d-]+)(\.iam\.gserviceaccount\.com)$/\2/')

OLD_KEY_ID_SHORT=$(echo ${OLD_KEY_ID} | cut -c 1-12)                      # short version of the key id
OLD_KEY_FILES_ARRAY=( $(grep -l ${OLD_KEY_ID}  ~/.config/gcloud/*.json) ) # find old key files matching key id

debugMessage "KEY_ACTION         : ${KEY_ACTION}"
debugMessage "IAM_ACCT           : ${IAM_ACCT}"
debugMessage "IAM_USER           : ${IAM_USER}"
debugMessage "IAM_PROJECT        : ${IAM_PROJECT}"
debugMessage "OLD_KEY_ID         : ${OLD_KEY_ID}"      
debugMessage "OLD_KEY_FILES_ARRAY: ${#OLD_KEY_FILES_ARRAY[*]} (items)"

# SHOW current keys before creating/deleting any...
printBanner "STARTING List of keys"
gcloud iam service-accounts keys list --iam-account ${IAM_ACCT}     # list the current keys


if [ ${KEY_ACTION} == "delete" ];then
	deleteOldKey     # call delete old function
	KEY_ID="n/a"     # set as n/a if called as delete only mode
elif [ ${KEY_ACTION} == "create" ];then
	createNewKey     # call create new function
	OLD_KEY_ID="n/a" # set as n/a if called as create only mode
elif [ ${KEY_ACTION} == "rotate" ];then
	createNewKey     # call create new function
	deleteOldKey     # call delete old function
else
	# if nothing matched, just do list operation
	KEY_ID="n/a"     # set as n/a if called as delete only mode
	OLD_KEY_ID="n/a" # set as n/a if called as create only mode
fi

printBanner "Key Rotation Info"
echo -e "\033[34mAction :\033[0m ${KEY_ACTION}"
echo -e "\033[34mAccount:\033[0m ${IAM_ACCT}"
echo -e "\033[34mProject:\033[0m ${IAM_PROJECT}"
echo -e "\033[34mDeleted:\033[0m ${OLD_KEY_ID}"
echo -e "\033[34mCreated:\033[0m ${KEY_ID}"

# SHOW matching content in the local ~/.config/gcloud dir 
printBanner "Content of: ~/.config/gcloud/${IAM_PROJECT}*"
ls -l ~/.config/gcloud/${IAM_PROJECT}*.json*

# SHOW current keys after creating...
printBanner "ENDING List of keys"
gcloud iam service-accounts keys list --iam-account ${IAM_ACCT}        # list the current keys

if [ ${KEY_ACTION} == "create" ] || [ ${KEY_ACTION} == "rotate" ] || [ ${KEY_ACTION} == "delete" ];then 
	printBanner "NOTICE"
	echo "you may need to update aliases in your profile which export the GOOGLE_APPLICATION_CREDENTIALS env var, such as in the following example..." 
	echo
	echo "     alias gckey_${IAM_PROJECT}='export GOOGLE_APPLICATION_CREDENTIALS=${KEY_FILE_NEW}'"
	echo
fi




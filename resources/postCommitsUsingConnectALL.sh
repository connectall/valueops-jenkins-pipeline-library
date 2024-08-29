#!/bin/bash

# ######################## Logging functions ########################

debug() {
  if [ "$DEBUG_VALUEOPS_INSIGHTS_LIBRARY" = "true" ]; then
    echo "DEBUG: $1"
  fi
}

info() {
    echo "INFO: $1"
}

exitWithError() {
    echo "ERROR: $1"
    exit 1
}

# ######################## Helper functions ########################

validate_input() {
  if [ -z "$1" ]; then
    exitWithError "$2 is not set"
  fi
}

create_commit_log() {
  local git_repo_loc=$1
  local log_path=$2
  local from_commit=$3
  local to_commit=$4
  
  touch "$log_path"
  git --git-dir="$git_repo_loc/.git" log --pretty=format:'%H %ad' --date=iso "$from_commit".."$to_commit" > "$log_path"
  echo >> "$log_path"
}

parse_commit_log_timestamp() {
  local timestamp="$1"
  local formatted_date

  if [[ "$OSTYPE" == "darwin"* ]]; then
      # macOS
      formatted_date=$(date -j -f '%Y-%m-%d %H:%M:%S %z' "$timestamp" +'%Y-%m-%dT%H:%M:%S%z')
  else
      # Linux and other Unix-like systems
      formatted_date=$(date -d "$timestamp" +'%Y-%m-%dT%H:%M:%S%z')
  fi
  
  echo "$formatted_date"
}

post_commit() {
    local _commitId=$1
    local _commitTimestamp=$2

     # Parse the date
    _formattedTimestamp=$(parse_commit_log_timestamp "$_commitTimestamp")
   
    json="{
            \"appLinkName\":\"$AUTOMATION_NAME\",
            \"fields\": {
                \"CommitId\":\"$_commitId\",
                \"CommitTimestamp\":\"$_formattedTimestamp\",
                \"DeployId\": \"$DEPLOY_BUILD_ID\"
            }
        }"
    
    debug "Posting Commit to ConnectALL"
    debug "$json"

    response=$(curl -s -o /dev/null -X POST -H "Content-Type: application/json;charset=UTF-8" -d "$json" "$API_URL/connectall/api/2/postRecord?apikey=$API_KEY")
    if [ $? -ne 0 ]; then
        exitWithError "Could not connect to $API_URL" 
    fi
    
    debug "$response"
    echo "$response"
}

# ######################## Main script ########################

info "Posting Commits to ConnectALL with Build ID: $DEPLOY_BUILD_ID from repo $GIT_REPO_LOC"

debug "API_URL: $API_URL"
debug "AUTOMATION_NAME: $AUTOMATION_NAME"
debug "DEPLOY_BUILD_ID: $DEPLOY_BUILD_ID"
debug "GIT_REPO_LOC: $GIT_REPO_LOC"
debug "CURRENT_BUILD_COMMIT: $CURRENT_BUILD_COMMIT"
debug "PREVIOUS_SUCCESS_BUILD_COMMIT: $PREVIOUS_SUCCESS_BUILD_COMMIT"

# Validate input variables
validate_input "$API_KEY" "ConnectALL_Api_Key"
validate_input "$API_URL" "ConnectALL_Api_Url"
validate_input "$AUTOMATION_NAME" "AutomationName"
validate_input "$DEPLOY_BUILD_ID" "DeployId"
validate_input "$GIT_REPO_LOC" "GitRepoLoc"
validate_input "$PREVIOUS_SUCCESS_BUILD_COMMIT" "PrevSuccessBuildCommit"
validate_input "$CURRENT_BUILD_COMMIT" "CurrentBuildCommit"

# Create a commit log
log_file_path="$GIT_REPO_LOC/commit_log"
create_commit_log "$GIT_REPO_LOC" "$log_file_path" "$PREVIOUS_SUCCESS_BUILD_COMMIT" "$CURRENT_BUILD_COMMIT"

# counter to keep track of the number of commits posted
commit_count=0

## Loop over the commit log and post commits to ConnectALL
while IFS= read -r line; do
    # Read the line
    read -r commit_id commit_timestamp <<< "$line"
   
    # Post commit to ConnectALL using AUTOMATION_NAME on DEPLOY_BUILD_ID
    debug "Posting commit $commit_id with timestamp $commit_timestamp to ConnectALL"
    post_commit "$commit_id" "$commit_timestamp"
    if [ $? -ne 0 ]; then
      exitWithError "Failed to create VSMChange in Insights"
    fi
    
    # Increment commit count
    commit_count=$((commit_count+1))

done < "$log_file_path"


info "$commit_count commits posted successfully to ConnectALL with Build ID: $DEPLOY_BUILD_ID"



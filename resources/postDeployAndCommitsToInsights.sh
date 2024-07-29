#!/bin/bash

echo "API_URL: $API_URL"
echo "API_WORKSPACE_OID: $API_WORKSPACE_OID"
echo "DEPLOY_COMPONENT: $DEPLOY_COMPONENT"
echo "DEPLOY_BUILD_ID: $DEPLOY_BUILD_ID"
echo "DEPLOY_START_TIME: $DEPLOY_START_TIME"
echo "DEPLOY_END_TIME: $DEPLOY_END_TIME"
echo "DEPLOY_IS_SUCCESSFUL: $DEPLOY_IS_SUCCESSFUL"
echo "DEPLOY_MAIN_REVISION: $DEPLOY_MAIN_REVISION"
echo "PREVIOUS_SUCCESS_BUILD_COMMIT: $PREVIOUS_SUCCESS_BUILD_COMMIT"
echo "CURRENT_BUILD_COMMIT: $CURRENT_BUILD_COMMIT"
echo "GIT_REPO_LOC: $GIT_REPO_LOC"

if [ -z "$API_KEY" ]; then
  echo "API_KEY is not set"
  exit 1
fi

if [ -z "$API_URL" ]; then
  echo "API_URL is not set"
  exit 1
fi

if [ -z "$API_WORKSPACE_OID" ]; then
  echo "API_WORKSPACE_OID is not set"
  exit 1
fi

if [ -z "$DEPLOY_COMPONENT" ]; then
  echo "DEPLOY_COMPONENT is not set"
  exit 1
fi

if [ -z "$DEPLOY_BUILD_ID" ]; then
  echo "DEPLOY_BUILD_ID is not set"
  exit 1
fi

if [ -z "$DEPLOY_START_TIME" ]; then
  echo "DEPLOY_START_TIME is not set"
  exit 1
fi

if [ -z "$DEPLOY_END_TIME" ]; then
  echo "DEPLOY_END_TIME is not set"
  exit 1
fi

if [ -z "$DEPLOY_IS_SUCCESSFUL" ]; then
  echo "DEPLOY_IS_SUCCESSFUL is not set"
  exit 1
fi

if [ -z "$DEPLOY_MAIN_REVISION" ]; then
  echo "DEPLOY_MAIN_REVISION is not set"
  exit 1
fi

if [ -z "$PREVIOUS_SUCCESS_BUILD_COMMIT" ]; then
  echo "PREVIOUS_SUCCESS_BUILD_COMMIT is not set"
  exit 1
fi

if [ -z "$CURRENT_BUILD_COMMIT" ]; then
  echo "CURRENT_BUILD_COMMIT is not set"
  exit 1
fi

if [ -z "$GIT_REPO_LOC" ]; then
  echo "GIT_REPO_LOC is not set"
  exit 1
fi

parse_millis() {
    local ms=$1
    local seconds=$((ms / 1000))

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        date -r $seconds -u +"%Y-%m-%dT%H:%M:%S%z"
    else
        # Linux and other Unix-like systems
        date -u -d @$seconds +"%Y-%m-%dT%H:%M:%S%z"
    fi
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

make_vsm_deploy() {
  echo "Creating VSMDeploy" >&2
  
  local deploy_is_successful=$1
  local formatted_start_date=$2
  local formatted_end_date=$3
  local deploy_main_revision=$4
  local deploy_component=$5
  local deploy_build_id=$6
  
  json="{ 
    \"VSMDeploy\": {
      \"IsSuccessful\": $deploy_is_successful,
      \"TimeCreated\":  \"$formatted_start_date\",
      \"TimeDeployed\": \"$formatted_end_date\",
      \"MainRevision\": \"$deploy_main_revision\",
      \"Component\":    \"vsmcomponent/$deploy_component\",
      \"BuildId\":      \"$deploy_build_id\"
    }
  }"
  
  echo "Posting VSMDeploy to Insights" >&2
  echo "$json" >&2
  
  response=$(curl -s \
     -H "ZSESSIONID: $API_KEY" \
     -H 'Content-Type: application/json' \
     -X POST \
     -d "$json" \
     "$API_URL/vsmdeploy/create?workspace=workspace/$API_WORKSPACE_OID")
  if [ $? -ne 0 ]; then
    echo "Could not connect to $API_URL" >&2
    exit 1
  fi
  
  echo "$response"
}

get_object_id_from_response() {
  local response="$1"
  
  local object_id
  object_id=$(echo "$response" | grep -o '"ObjectID":[^,}]*' | head -1 | sed 's/.*: //')
  
  echo "$object_id"
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

make_vsm_change() {
  local commit_id=$1
  local timestamp=$2
  local deploy_id=$3
  
  json="{
      \"VSMChange\": {
        \"Revision\":   \"$commit_id\",
        \"CommitTime\": \"$formatted_date\",
        \"Deploy\":     \"$deploy_id\"
      }
    }"
    
  echo "Posting VSMChange to Insights" >&2
  echo "$json" >&2
  
  response=$(curl -s -H "ZSESSIONID: $API_KEY" -H 'Content-Type: application/json' -X POST -d "$json" "$API_URL/vsmchange/create?workspace=workspace/$API_WORKSPACE_OID")
  
  if [ $? -ne 0 ]; then
    echo "Could not connect to $API_URL" >&2
    exit 1
  fi
  
  echo "$response"
}

_formatted_start_date=$(parse_millis "$DEPLOY_START_TIME")
if [ $? -ne 0 ]; then
  echo "Could not parse start time: $DEPLOY_START_TIME"
  exit 1
fi

_formatted_end_date=$(parse_millis "$DEPLOY_END_TIME")
if [ $? -ne 0 ]; then
  echo "Could not parse end time: $DEPLOY_END_TIME"
  exit 1
fi

### Script flow starts here
echo ""
## Make a Deploy
deploy_response=$(make_vsm_deploy "$DEPLOY_IS_SUCCESSFUL" "$_formatted_start_date" "$_formatted_end_date" "$DEPLOY_MAIN_REVISION" "$DEPLOY_COMPONENT" "$DEPLOY_BUILD_ID")

## Exit if error
if [ $? -ne 0 ]; then
  echo "Failed to create deploy in Insights"
  exit 1
fi

## Get Deploy ID
deploy_id=$(get_object_id_from_response "$deploy_response")

## Exit if it we can't find the deploy id in the response (this could be for many reasons)
if [ -z "$deploy_id" ]; then
  echo "Failed to create deploy in Insights, no deploy id found in response." >&2
  echo "$deploy_response"
  exit 1
fi

echo "Deploy created successfully"
echo "VSMDeploy.ObjectId: $deploy_id"

## Create the commit log we're going to loop over
create_commit_log "$GIT_REPO_LOC" "$GIT_REPO_LOC/commit_log" "$PREVIOUS_SUCCESS_BUILD_COMMIT" "$CURRENT_BUILD_COMMIT"

## Loop over the commit log and make VSMChanges
while IFS= read -r line; do
    # Read the line
    read -r commit_id timestamp <<< "$line"

    # Parse the date
    formatted_date=$(parse_commit_log_timestamp "$timestamp")
    
    
    # Make the VSMChange
    change_response=$(make_vsm_change "$commit_id" "$formatted_date" "$deploy_id")

    # Exit if error
    if [ $? -ne 0 ]; then
      echo "Failed to create VSMChange in Insights" >&2
      exit 1
    fi
    
    change_id=$(get_object_id_from_response "$change_response")
    
    if [ -z "$change_id" ]; then
      echo "Failed to create VSMChange in Insights, no change id found in response." >&2
      echo "$change_response"
      exit 1
    fi
    
    echo "VSMChange created successfully"
    echo "VSMChange.ObjectId: $change_id"
done < "$GIT_REPO_LOC/commit_log"
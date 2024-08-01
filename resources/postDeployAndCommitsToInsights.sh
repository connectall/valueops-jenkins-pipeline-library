#!/bin/bash

echo "API_URL: $API_URL"
echo "API_WORKSPACE_OID: $API_WORKSPACE_OID"
echo "DEPLOY_COMPONENT_NAME: $DEPLOY_COMPONENT_NAME"
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

if [ -z "$DEPLOY_COMPONENT_NAME" ]; then
  echo "DEPLOY_COMPONENT_NAME is not set"
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

full_api_url="$API_URL/slm/webservice/v2.0"

parse_millis() {
    local ms=$1
    local seconds=$((ms / 1000))

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        date -r $seconds -u +"%Y-%m-%dT%H:%M:%SZ"
    else
        # Linux and other Unix-like systems
        date -u -d @$seconds +"%Y-%m-%dT%H:%M:%SZ"
    fi
}

parse_commit_log_timestamp() {
  local timestamp="$1"

  local formatted_date

  if [[ "$OSTYPE" == "darwin"* ]]; then
      # macOS
      formatted_date=$(date -j -f '%Y-%m-%d %H:%M:%S %z' "$timestamp" +'%Y-%m-%dT%H:%M:%SZ')
  else
      # Linux and other Unix-like systems
      formatted_date=$(date -d "$timestamp" +'%Y-%m-%dT%H:%M:%SZ')
  fi
  
  echo "$formatted_date"
}

make_vsm_deploy() {
  echo "Creating VSMDeploy" >&2
  
  local deploy_is_successful=$1
  local formatted_start_date=$2
  local formatted_end_date=$3
  local deploy_main_revision=$4
  local deploy_component_oid=$5
  local deploy_build_id=$6
  
  json="{"
  json+="\"VSMDeploy\": {"
  
  if [ ! -z "$deploy_is_successful" ] && [ "$deploy_is_successful" != "null" ]; then
    json+="\"IsSuccessful\": $deploy_is_successful,"
  fi
  
  if [ ! -z "$formatted_end_date" ]; then
    json+="\"TimeDeployed\": \"$formatted_end_date\","
  fi
  
  json+="\"TimeCreated\":  \"$formatted_start_date\","
  json+="\"MainRevision\": \"$deploy_main_revision\","
  json+="\"Component\":    \"vsmcomponent/$deploy_component_oid\","
  json+="\"BuildId\":      \"$deploy_build_id\""
  json+="}"
  json+="}"
  
  echo "Posting VSMDeploy to Insights" >&2
  echo "$json" >&2
  
  response=$(curl -s \
     -H "ZSESSIONID: $API_KEY" \
     -H 'Content-Type: application/json' \
     -X POST \
     -d "$json" \
     "$full_api_url/vsmdeploy/create?workspace=workspace/$API_WORKSPACE_OID")
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
  
  response=$(curl -s -H "ZSESSIONID: $API_KEY" -H 'Content-Type: application/json' -X POST -d "$json" "$full_api_url/vsmchange/create?workspace=workspace/$API_WORKSPACE_OID")
  
  if [ $? -ne 0 ]; then
    echo "Could not connect to $API_URL" >&2
    exit 1
  fi
  
  echo "$response"
}

query_component() {
    local name=$1
    local response
    response=$(curl -s -H "ZSESSIONID: $API_KEY" "$full_api_url/vsmcomponent?query=(Name%20=%20$name)&workspace=workspace/$API_WORKSPACE_OID&fetch=ObjectID")
    
    if [ $? -ne 0 ]; then
      echo "Could not connect to $API_URL" >&2
      exit 1
    fi
    
    echo "$response"
}

formatted_start_date=$(parse_millis "$DEPLOY_START_TIME")
if [ $? -ne 0 ]; then
  echo "Could not parse start time: $DEPLOY_START_TIME"
  exit 1
fi

if [ -z "$DEPLOY_END_TIME" ] || [ "$DEPLOY_END_TIME" == "null" ]; then
  formatted_end_date=""
else
  formatted_end_date=$(parse_millis "$DEPLOY_END_TIME")
  if [ $? -ne 0 ]; then
    echo "Could not parse end time: $DEPLOY_END_TIME"
    exit 1
  fi
fi

### Script flow starts here

## Find the component by name
component_response=$(query_component "$DEPLOY_COMPONENT_NAME")

if [ $? -ne 0 ]; then
  echo "Failed to query component in Insights"
  exit 1
fi

component_id=$(get_object_id_from_response "$component_response")

if [ -z "$component_id" ]; then
  echo "Failed to find component in Insights, no component id found in response." >&2
  echo "$component_response"
  exit 1
fi

## Make a Deploy
deploy_response=$(make_vsm_deploy "$DEPLOY_IS_SUCCESSFUL" "$formatted_start_date" "$formatted_end_date" "$DEPLOY_MAIN_REVISION" "$component_id" "$DEPLOY_BUILD_ID")

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

log_file_path="$GIT_REPO_LOC/commit_log"

## Create the commit log we're going to loop over
create_commit_log "$GIT_REPO_LOC" "$log_file_path" "$PREVIOUS_SUCCESS_BUILD_COMMIT" "$CURRENT_BUILD_COMMIT"

## Loop over the commit log and make VSMChanges
while IFS= read -r line; do
    # Read the line
    read -r commit_id timestamp <<< "$line"
    
    # Exit if we can't parse the line
    if [ -z "$commit_id" ] || [ -z "$timestamp" ]; then
      echo "Failed to parse commit log line: $line" >&2
      exit 1
    fi

    # Parse the date
    formatted_date=$(parse_commit_log_timestamp "$timestamp")
    
    # Make the VSMChange
    change_response=$(make_vsm_change "$commit_id" "$formatted_date" "$deploy_id")

    # Exit if error
    if [ $? -ne 0 ]; then
      echo "Failed to create VSMChange in Insights"
      exit 1
    fi
    
    # Try to extract the change id
    change_id=$(get_object_id_from_response "$change_response")
    
    # Exit if it we can't find the change id in the response (this could be for many reasons)
    if [ -z "$change_id" ]; then
      echo "Failed to create VSMChange in Insights, no change id found in response."
      echo "$change_response"
      exit 1
    fi
    
    echo "VSMChange created successfully"
    echo "VSMChange.ObjectId: $change_id"
done < "$log_file_path"
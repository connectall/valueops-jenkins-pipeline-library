#!/bin/bash

echo "API_URL: $API_URL"
echo "API_WORKSPACE_OID: $API_WORKSPACE_OID"
echo "DEPLOY_BUILD_ID: $DEPLOY_BUILD_ID"
echo "DEPLOY_END_TIME: $DEPLOY_END_TIME"
echo "DEPLOY_IS_SUCCESSFUL: $DEPLOY_IS_SUCCESSFUL"

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

if [ -z "$DEPLOY_BUILD_ID" ]; then
  echo "DEPLOY_BUILD_ID is not set"
  exit 1
fi

if [ -z "$DEPLOY_IS_SUCCESSFUL" ]; then
  echo "DEPLOY_IS_SUCCESSFUL is not set"
  exit 1
fi

if [ -z "$DEPLOY_END_TIME" ]; then
  echo "DEPLOY_END_TIME is not set"
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

formatted_end_date=$(parse_millis "$DEPLOY_END_TIME")
if [ $? -ne 0 ]; then
  echo "Could not parse end time: $DEPLOY_END_TIME"
  exit 1
fi

query_deploy_id() {
    local build_id=$1
    local response
    response=$(curl -s -H "ZSESSIONID: $API_KEY" "$API_URL/vsmdeploy?query=(BuildId%20=%20$build_id)&workspace=workspace/$API_WORKSPACE_OID&fetch=ObjectID")
    
    if [ $? -ne 0 ]; then
      echo "Could not connect to $API_URL"
      exit 1
    fi
    
    echo "$response"
}

get_deploy_id_from_response() {
    local deploy_response="$1"
    
    local deploy_id
    deploy_id=$(echo "$deploy_response" | grep -o '"ObjectID":[^,}]*' | head -1 | sed 's/.*: //')
    
    if [ -z "$deploy_id" ]; then
        echo "No deploy found for build $DEPLOY_BUILD_ID in response" >&2
        echo "$deploy_response" >&2
        exit 1
    fi
    
    echo "$deploy_id"
}

update_deploy() {
    local deploy_id=$1
    local time_deployed=$2
    local deploy_is_successful=$3
    
    json="{
        \"VSMDeploy\": {
            \"IsSuccessful\": \"$deploy_is_successful\",
            \"TimeDeployed\": \"$time_deployed\"
        } 
    }"
    
    echo "Updating deploy in Insights"
    echo "$json"
    
    response=$(curl -s -o /dev/null -H "ZSESSIONID: $API_KEY" -H 'Content-Type: application/json' -X POST -d "$json" "$API_URL/vsmdeploy/$deploy_id?workspace=workspace/$API_WORKSPACE_OID")
    
    if [ $? -ne 0 ]; then
        echo "Could not connect to $API_URL"
        exit 1
    fi
    
    echo "$response"
}

### Script flow starts here

## Find the deploy by build id
deploy_response=$(query_deploy_id "$DEPLOY_BUILD_ID")

## Exit if error
if [ $? -ne 0 ]; then
    echo "Failed to query deploy in Insights"
    exit 1
fi

## Get Deploy ID out of the response
deploy_id=$(get_deploy_id_from_response "$deploy_response")

## Exit if it we can't find the deploy id in the response (this could be for many reasons)
if [ -z "$deploy_id" ]; then
    echo "No deploy found for build $DEPLOY_BUILD_ID in response" >&2
    echo "$deploy_response" >&2
    exit 1
fi

echo "Deploy found successfully"
echo "VSMDeploy.ObjectId: $deploy_id"

## Update the deploy
update_deploy "$deploy_id" "$formatted_end_date" "$DEPLOY_IS_SUCCESSFUL"

## Exit if error
if [ $? -ne 0 ]; then
    echo "Failed to update deploy in Insights"
    exit 1
fi

echo ""
echo "Deploy updated successfully"
echo "VSMDeploy.ObjectId: $deploy_id"
